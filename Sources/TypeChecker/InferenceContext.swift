//
//  Context.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

import Foundation
import TalkTalkSyntax

typealias VariableID = Int

enum InferenceError: Equatable, Hashable {
	case undefinedVariable(String)
	case unknownError(String)
	case constraintError(String)
	case argumentError(String)
	case typeError(String)
	case memberNotFound(StructType, String)
	case missingConstraint(InferenceType)
}

// If we're inside a type's body, we can save methods/properties in here
class TypeContext {
	var selfVar: TypeVariable
	var methods: [String: InferenceResult]
	var initializers: [String: InferenceResult]
	var properties: [String: InferenceResult]
	var typeParameters: [InferenceResult]

	init(
		selfVar: TypeVariable,
		methods: [String: InferenceResult] = [:],
		initializers: [String: InferenceResult] = [:],
		properties: [String: InferenceResult] = [:],
		typeParameters: [InferenceResult] = []
	) {
		self.selfVar = selfVar
		self.methods = methods
		self.initializers = initializers
		self.properties = properties
		self.typeParameters = typeParameters
	}

	func instantiate(_ result: InferenceResult, in context: InferenceContext) -> InferenceResult {
		switch result {
		case let .type(.typeVar(typeVar)):
			// Create fresh type variables for instances
			.type(.typeVar(context.freshTypeVariable(typeVar.name ?? "")))
		default:
			result
		}
	}
}

class InferenceContext: CustomDebugStringConvertible {
	internal var environment: Environment
	var parent: InferenceContext?
	let depth: Int
	var errors: [InferenceError] = []
	var constraints: Constraints
	var substitutions: [TypeVariable: InferenceType] = [:]
	var typeContext: TypeContext?
	var namedVariables: [String: InferenceType] = [:]
	var nextID: VariableID = 0

	init(
		parent: InferenceContext? = nil,
		environment: Environment,
		constraints: Constraints,
		substitutions: [TypeVariable: InferenceType] = [:],
		typeContext: TypeContext? = nil
	) {
		self.depth = (parent?.depth ?? 0) + 1
		self.parent = parent
		self.environment = environment
		self.constraints = constraints
		self.substitutions = substitutions
		self.typeContext = typeContext

		log("New context with depth \(depth)", prefix: " * ")
	}

	var debugDescription: String {
		var result = "InferenceContext parent: \(parent == nil ? "none" : typeContext?.selfVar.name ?? "<?>")"
		result += "Environment:\n"

		for (key, val) in environment.types {
			result += "- syntax id \(key) : \(val.description)\n"
		}

		return result
	}

	func childContext() -> InferenceContext {
		InferenceContext(
			parent: self,
			environment: environment.childEnvironment(),
			constraints: constraints,
			substitutions: substitutions,
			typeContext: typeContext
		)
	}

	func childTypeContext(withSelf: TypeVariable) -> InferenceContext {
		InferenceContext(
			parent: self,
			environment: environment,
			constraints: constraints,
			substitutions: substitutions,
			typeContext: typeContext ?? TypeContext(selfVar: withSelf)
		)
	}

	func lookupTypeContext() -> TypeContext? {
		if let typeContext {
			return typeContext
		}

		return parent?.typeContext
	}

	func solve() -> InferenceContext {
		var solver = Solver(context: self, constraints: constraints)
		return solver.solve()
	}

	func addError(_ inferrenceError: InferenceError, to expr: any Syntax) {
		errors.append(inferrenceError)
		environment.extend(expr, with: .type(.error(inferrenceError)))
	}

	func extend(_ syntax: any Syntax, with result: InferenceResult) {
		environment.extend(syntax, with: result)
	}

	func isFreeVariable(_ type: InferenceType) -> Bool {
		if case let .typeVar(variable) = type {
			// Check if the variable exists in the context's substitution map
			// If it's not in the substitution map, it's a free variable
			return substitutions[variable] == nil
		}

		return false
	}

	func trackReturns(_ block: () throws -> Void) throws -> Set<InferenceResult> {
		try environment.trackingReturns(block: block)
	}

	func trackReturn(_ result: InferenceResult) {
		environment.trackReturn(result)
	}

	func lookupVariable(named name: String) -> InferenceType? {
		namedVariables[name] ?? parent?.lookupVariable(named: name)
	}

	func lookupSubstitution(named name: String) -> InferenceType? {
		substitutions.first(where: { variable, _ in variable.name == name })?.value
	}

	// Look up inference results for a particular syntax node
	subscript(syntax: any Syntax) -> InferenceResult? {
		get {
			switch environment[syntax] ?? parent?[syntax] {
			case let .scheme(scheme): return .scheme(scheme)
			case let .type(type): return .type(applySubstitutions(to: type))
			default:
				return nil
			}
		}

		set {
			environment[syntax] = newValue
		}
	}

	@discardableResult func addError(_ inferenceError: InferenceError) -> InferenceType {
		errors.append(inferenceError)
		return .error(inferenceError)
	}

	func freshTypeVariable(_ name: String, creatingContext: InferenceContext? = nil) -> TypeVariable {
		if let parent {
			return parent.freshTypeVariable(name, creatingContext: creatingContext ?? self)
		}

		defer { nextID += 1 }

		log("New type variable: \(name), T(\(nextID))", prefix: " + ", context: creatingContext ?? self)

		return TypeVariable(name, nextID)
	}

	func bind(typeVar: TypeVariable, to type: InferenceType) {
		guard .typeVar(typeVar) != type else {
			fatalError("cannot bind type var to itself")
		}

		substitutions[typeVar] = type
	}

	func applySubstitutions(
		to type: InferenceType,
		with substitutions: [TypeVariable: InferenceType],
		count: Int = 0
	) -> InferenceType {
		switch type {
		case let .typeVar(typeVariable):
			// Reach down recursively as long as we can to try to find the result
			if case let .typeVar(child) = substitutions[typeVariable], count < 100 {
				return applySubstitutions(to: .typeVar(child), with: substitutions, count: count + 1)
			}

			return substitutions[typeVariable] ?? type
		case let .function(params, returning):
			return .function(params.map { applySubstitutions(to: $0) }, applySubstitutions(to: returning))
		default:
			return type // Base/error/void types don't get substitutions
		}
	}

	func applySubstitutions(to type: InferenceType, withParents: Bool = false) -> InferenceType {
		let parentResult = parent?.applySubstitutions(to: type) ?? type
		return applySubstitutions(to: parentResult, with: substitutions)
	}

	// See if these types are compatible. If so, bind 'em.
	func unify(_ typeA: InferenceType, _ typeB: InferenceType) {
		let a = applySubstitutions(to: typeA)
		let b = applySubstitutions(to: typeB)

		log("Unifying \(typeA) <-> \(typeB)", prefix: " & ")

		switch (a, b) {
		case let (.base(a), .base(b)) where a != b:
			fatalError("Cannot unify \(a) and \(b)")
		case (.base(_), .typeVar(let b)):
			bind(typeVar: b, to: a)
			print("     Got a base type: \(a)")
		case (.typeVar(let a), .base(_)):
			bind(typeVar: a, to: b)
			print("     Got a base type: \(b)")
		case let (.typeVar(v), _) where .typeVar(v) != b:
			bind(typeVar: v, to: b)
		case let (_, .typeVar(v)) where .typeVar(v) != a:
			bind(typeVar: v, to: a)
		case let (.function(paramsA, returnA), .function(paramsB, returnB)):
			zip(paramsA, paramsB).forEach { unify($0, $1) }
			unify(returnA, returnB)
		case let (.structType(a), .structType(b)) where a.name == b.name:
			// Unify struct type parameters if needed
			break
		case let (.structInstance(a), .structInstance(b)) where a.type.name == b.type.name:
			// Unify struct instance type parameters if needed
			break
		default:
			addError(.typeError("Cannot unify \(a) and \(b)"))
		}
	}

	// Turn this scheme into an actual type, using whatever environment we
	// have at this moment
	func instantiate(scheme: Scheme) -> InferenceType {
		var localSubstitutions: [TypeVariable: InferenceType] = [:]

		// Replace the scheme's variables with fresh type variables
		for case let .typeVar(variable) in scheme.variables {
			localSubstitutions[variable] = .typeVar(freshTypeVariable((variable.name ?? "<unnamed>") + " [instantiated]"))
		}

		return applySubstitutions(to: scheme.type, with: localSubstitutions)
	}

	func log(_ msg: String, prefix: String, context: InferenceContext? = nil) {
		let context = context ?? self
		print("\(context.depth) " + prefix + msg)
	}
}
