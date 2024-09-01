//
//  Environment.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkBytecode
import TalkTalkSyntax
import TypeChecker

// An Environment represents the type environment for some scope
public class Environment {
	private var parent: Environment?
	private var locals: [String: Binding]
	private var structTypes: [String: StructType] = [:]

	let inferenceContext: InferenceContext

	public var isModuleScope: Bool
	public var lexicalScope: LexicalScope?
	public var captures: [Capture]
	public var capturedValues: [Binding]
	public var importedModules: [AnalysisModule]
	public var importedSymbols: [Symbol: Binding] = [:]
	public var errors: [AnalysisError] = []
	public var exprStmtExitBehavior: AnalyzedExprStmt.ExitBehavior = .pop
	public var symbolGenerator: SymbolGenerator
	public var isInTypeParameters: Bool = false

	public private(set) var shouldReportErrors: Bool = true

	public init(
		inferenceContext: InferenceContext,
		isModuleScope: Bool = false,
		symbolGenerator: SymbolGenerator = .init(moduleName: "None", parent: nil),
		importedModules: [AnalysisModule] = [],
		parent: Environment? = nil
	) {
		self.inferenceContext = inferenceContext
		self.isModuleScope = isModuleScope
		self.symbolGenerator = symbolGenerator
		self.parent = parent
		self.locals = [:]
		self.captures = []
		self.capturedValues = []
		self.importedModules = importedModules

		if symbolGenerator.moduleName != "Standard" {
			importStdlib()
		}
	}

	public static func topLevel(_ moduleName: String, inferenceContext: InferenceContext) -> Environment {
		Environment(
			inferenceContext: inferenceContext,
			isModuleScope: true,
			symbolGenerator: .init(moduleName: moduleName, parent: nil)
		)
	}

	public func type(for syntax: any Syntax) -> InferenceType {
		inferenceContext.lookup(syntax: syntax) ?? .any
	}

	public var moduleName: String {
		symbolGenerator.moduleName
	}

	public func ignoringErrors(perform: () throws -> Void) throws {
		defer { self.shouldReportErrors = true }
		shouldReportErrors = false
		try perform()
	}

	// We want to collect all errors at the top level module, so walk up ancestors then add it there
	public func report(_ kind: AnalysisErrorKind, at location: SourceLocation) -> AnalysisError {
		let error = AnalysisError(kind: kind, location: location)

		if let parent {
			return parent.report(kind, at: location)
		}

		errors.append(error)
		return error
	}

	public func add(namespace: String?) -> Environment {
		if let namespace {
			Environment(inferenceContext: inferenceContext, symbolGenerator: symbolGenerator.new(namespace: namespace), parent: self)
		} else {
			Environment(inferenceContext: inferenceContext, symbolGenerator: symbolGenerator, parent: self)
		}
	}

	public func withExitBehavior(_ behavior: AnalyzedExprStmt.ExitBehavior) -> Environment {
		let environment = add(namespace: nil)
		environment.exprStmtExitBehavior = behavior
		return environment
	}

	func addLexicalScope(_ scope: LexicalScope) -> Environment {
		let environment = Environment(inferenceContext: inferenceContext, symbolGenerator: symbolGenerator, parent: self)
		environment.lexicalScope = scope
		return environment
	}

	public func importModule(_ analysisModule: AnalysisModule) {
		importedModules.append(analysisModule)
	}

	public func define(struct name: String, as type: StructType) {
		structTypes[name] = type
	}

	public func define(parameter: String, as expr: any AnalyzedExpr) {
		locals[parameter] = Binding(
			name: parameter,
			location: expr.location,
			type: inferenceContext.lookup(syntax: expr) ?? .any,
			isParameter: true
		)
	}

	public func define(
		local: String,
		as expr: any Syntax,
		isMutable: Bool,
		isGlobal: Bool = false
	) {
		locals[local] = Binding(
			name: local,
			location: expr.location,
			definition: Definition(location: expr.semanticLocation ?? expr.location, type: inferenceContext.lookup(syntax: expr) ?? .void),
			type: inferenceContext.lookup(syntax: expr) ?? .void,
			isGlobal: isGlobal,
			isMutable: isMutable
		)
	}

	public var bindings: [Binding] {
		Array(locals.values)
	}

	public func allBindings() -> [Binding] {
		var result = Array(locals.values)
		var parent = parent

		while let nextParent = parent {
			result.append(contentsOf: nextParent.allBindings())
			parent = nextParent
		}

		result.append(contentsOf: inferenceContext.namedVariables.compactMap {
			Binding(name: $0.key, location: [.synthetic(.identifier)], type: $0.value)
		})

		result.append(contentsOf: BuiltinFunction.list.map { $0.binding(in: self) })
		return result
	}

	public func infer(_ name: String) -> Binding? {
		if let local = locals[name] {
			return local
		}

		return parent?.infer(name)
	}

	func getLexicalScope() -> LexicalScope? {
		return lexicalScope ?? parent?.getLexicalScope()
	}

	public func lookup(_ name: String) -> Binding? {
		if let local = locals[name] {
			return local
		}

		if let existingCapture = captures.first(where: { $0.name == name }) {
			return existingCapture.binding
		}

		if let capture = capture(name: name) {
			captures.append(capture)
			return capture.binding
		}

		if let builtinFunction = BuiltinFunction.list.first(where: { $0.name == name }) {
			return builtinFunction.binding(in: self)
		}

		for module in lookupImportedModules() {
			var symbol: Symbol?
			var global: (any ModuleGlobal)?

			if let value = module.moduleValue(named: name) {
				symbol = value.symbol
				global = value
			} else if let function = module.moduleFunction(named: name) {
				symbol = function.symbol
				global = function
			} else if let type = module.moduleStruct(named: name) {
				symbol = type.symbol
				global = type
			}

			guard let symbol, let global else {
				continue
			}

			let binding = Binding(
				name: name,
				location: global.location,
				type: global.typeID,
				externalModule: module
			)

			importBinding(as: symbol, from: module.name, binding: binding)

			return binding
		}

		return nil
	}

	func importStdlib() {
			_ = symbolGenerator.import(.struct("Standard", "Array"), from: "Standard")
			_ = symbolGenerator.import(.struct("Standard", "Dictionary"), from: "Standard")
			_ = symbolGenerator.import(.struct("Standard", "String"), from: "Standard")
			_ = symbolGenerator.import(.struct("Standard", "Int"), from: "Standard")

			if let stdlib = importedModules.first(where: { $0.name == "Standard" }) {
				importBinding(
					as: symbolGenerator.import(.struct("Standard", "Array"), from: "Standard"),
					from: "Standard",
					binding: .init(
						name: "Array",
						location: [.synthetic(.identifier)],
						type: inferenceContext.namedVariables["Array"]!,
						externalModule: stdlib
					)
				)

				importBinding(
					as: symbolGenerator.import(.struct("Standard", "String"), from: "Standard"),
					from: "Standard",
					binding: .init(
						name: "String",
						location: [.synthetic(.identifier)],
						type: inferenceContext.namedVariables["String"]!,
						externalModule: stdlib
					)
				)

				importBinding(
					as: symbolGenerator.import(.struct("Standard", "Int"), from: "Standard"),
					from: "Standard",
					binding: .init(
						name: "Int",
						location: [.synthetic(.identifier)],
						type: inferenceContext.namedVariables["Int"]!,
						externalModule: stdlib
					)
				)

				importBinding(
					as: symbolGenerator.import(.struct("Standard", "Dictionary"), from: "Standard"),
					from: "Standard",
					binding: .init(
						name: "Dictionary",
						location: [.synthetic(.identifier)],
						type: inferenceContext.namedVariables["Dictionary"]!,
						externalModule: stdlib
					)
				)
			}
		}

	func lookupImportedModules() -> [AnalysisModule] {
		if let parent {
			return parent.lookupImportedModules()
		}

		return importedModules
	}

	func importBinding(as symbol: Symbol, from moduleName: String, binding: Binding) {
			if moduleName == self.moduleName {
				return
			}

			if let parent {
				parent.importBinding(as: symbol, from: moduleName, binding: binding)
				return
			}

			assert(isModuleScope, "trying to import binding into non-module scope environment")

			importedSymbols[symbol] = binding
			_ = symbolGenerator.import(symbol, from: moduleName)
		}

	public func lookupStruct(named name: String) -> StructType? {
		if let type = structTypes[name] {
			return type
		}

		if let type = parent?.lookupStruct(named: name) {
			return type
		}

		for module in lookupImportedModules() {
			if let structType = module.structs[name] {
				importBinding(
					as: structType.symbol,
					from: module.name,
					binding: lookup(name)!
				)
				return StructType(
					name: name,
					properties: structType.properties,
					methods: structType.methods,
					typeParameters: structType.typeParameters
				)
			}
		}

		return nil
	}

	func capture(name: String) -> Capture? {
		if let local = locals[name] {
			local.isCaptured = true
			capturedValues.append(local)
			return Capture(name: name, binding: local, environment: self)
		}

		if let parent {
			return parent.capture(name: name)
		}

		return nil
	}
}
