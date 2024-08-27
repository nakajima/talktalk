//
//  Context.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

import TalkTalkSyntax

typealias VariableID = Int

enum InferenceError: Equatable, Hashable {
	case undefinedVariable(String)
	case unknownError(String)
	case constraintError(String)
	case argumentError(String)
	case typeError(String)
	case memberNotFound(StructType, String)
	case missingConstraint(InferenceType, ConstraintType)
}

// If we're inside a type's body, we can save methods/properties in here
class TypeContext {
	var selfVar: TypeVariable
	var methods: [String: InferenceResult]
	var initializers: [String: StructType.Initializer]
	var properties: [String: InferenceResult]
	var typeParameters: [String: InferenceResult]

	init(
		selfVar: TypeVariable,
		methods: [String : InferenceResult] = [:],
		initializers: [String : StructType.Initializer] = [:],
		properties: [String : InferenceResult] = [:],
		typeParameters: [String: InferenceResult] = [:]
	) {
		self.selfVar = selfVar
		self.methods = methods
		self.initializers = initializers
		self.properties = properties
		self.typeParameters = typeParameters
	}
}

class InferenceContext {
	private var environment: Environment
	var parent: InferenceContext?
	var lastVariableID = 0
	var errors: [InferenceError] = []
	var constraints: Constraints
	var substitutions: [TypeVariable: InferenceType] = [:]
	var typeContext: TypeContext?

	init(
		lastVariableID: Int = 0,
		parent: InferenceContext? = nil,
		environment: Environment,
		constraints: Constraints,
		substitutions: [TypeVariable: InferenceType] = [:],
		typeContext: TypeContext? = nil
	) {
		self.parent = parent
		self.lastVariableID = lastVariableID
		self.environment = environment
		self.constraints = constraints
		self.substitutions = substitutions
		self.typeContext = typeContext
	}

	func childContext() -> InferenceContext {
		InferenceContext(
			parent: self,
			environment: environment.childEnvironment(),
			constraints: constraints,
			substitutions: [:],
			typeContext: typeContext
		)
	}

	func childTypeContext(withSelf: TypeVariable) -> InferenceContext {
		InferenceContext(
			parent: self,
			environment: environment.childEnvironment(),
			constraints: constraints,
			substitutions: [:],
			typeContext: TypeContext(selfVar: withSelf)
		)
	}

	func lookupTypeContext() -> TypeContext? {
		if let typeContext {
			return typeContext
		}

		return parent?.typeContext
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
		environment.lookupVariable(named: name) ?? parent?.lookupVariable(named: name)
	}

	func lookupSubstitution(named name: String) -> InferenceType? {
		substitutions.first(where: { (variable, _) in variable.name == name })?.value
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

	func freshTypeVariable(_ name: String? = nil) -> TypeVariable {
		defer { lastVariableID += 1 }
		return TypeVariable(name, lastVariableID)
	}

	func bind(typeVar: TypeVariable, to type: InferenceType) {
		guard .typeVar(typeVar) != type else {
			fatalError("cannot bind type var to itself")
		}

		substitutions[typeVar] = type
	}

	func applyInstanceSubstitutions(for structType: StructType) -> InferenceType {
		#warning("TODO")
		// We need to call this method on struct instantiation, looking at args to try to unify
		// with our generic types
		return .void
	}

	func inherit(_ context: InferenceContext) {
		for (typeVar, substitution) in context.substitutions {
			self.substitutions[typeVar] = substitution
		}
	}

	func applySubstitutions(to type: InferenceType, with substitutions: [TypeVariable: InferenceType]) -> InferenceType {
		switch type {
		case .typeVar(let typeVariable):
			return substitutions[typeVariable] ?? type
		case .function(let params, let returning):
			return .function(params.map({ applySubstitutions(to: $0) }), applySubstitutions(to: returning))
		default:
			return type // Base/error/void types don't get substitutions
		}
	}

	func applySubstitutions(to type: InferenceType, withParents: Bool = false) -> InferenceType {
		if withParents {
			let result = applySubstitutions(to: type, with: self.substitutions)
			return parent?.applySubstitutions(to: result) ?? result
		}

		return applySubstitutions(to: type, with: self.substitutions)
	}

	// See if these types are compatible. If so, bind 'em.
	func unify(_ typeA: InferenceType, _ typeB: InferenceType) {
		switch (typeA, typeB) {
		case (.typeVar(let v), _):
			bind(typeVar: v, to: typeB)
		case (_, .typeVar(let v)):
			bind(typeVar: v, to: typeA)
		default:
			() // Nothing to do at this point
		}
	}

	// Turn this scheme into an actual type, using whatever environment we
	// have at this moment
	func instantiate(scheme: Scheme) -> InferenceType {
		var localSubstitutions: [TypeVariable: InferenceType] = [:]

		// Replace the scheme's variables with fresh type variables
		for case let .typeVar(variable) in scheme.variables {
			localSubstitutions[variable] = .typeVar(freshTypeVariable())
		}

		return applySubstitutions(to: scheme.type, with: localSubstitutions)
	}
}
