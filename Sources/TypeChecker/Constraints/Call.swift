//
//  Call.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/1/24.
//

import OrderedCollections
import TalkTalkCore

extension Constraints {
	struct Call: Constraint {
		let context: Context
		let callee: InferenceResult
		let args: [InferenceResult]
		let result: InferenceType
		let location: SourceLocation
		var retries: Int = 0

		var before: String {
			"Call(callee: \(callee.debugDescription), args: \(args.debugDescription), result: \(result.debugDescription))"
		}

		var after: String {
			let callee = context.applySubstitutions(to: callee)
			let args = args.map { context.applySubstitutions(to: $0) }
			let result = context.applySubstitutions(to: result)

			return "Call(callee: \(callee.debugDescription), args: \(args.debugDescription), result: \(result.debugDescription))"
		}

		func solve() throws {
			let result = callee.instantiate(in: context)
			let callee = context.applySubstitutions(to: result.type, with: result.variables.asResults)

			switch callee {
			case .function(let params, let returns):
				try solveFunction(callee: callee, freeVars: result.variables, params: params, returns: returns)
			case .struct(let type):
				try solveStruct(type: type, freeVars: result.variables)
			default:
				if retries > 1 {
					context.error("\(callee) not callable", at: location)
				} else {
					context.retry(self)
				}
			}
		}

		private func solveFunction(callee: InferenceType, freeVars: [TypeVariable: InferenceType], params: [InferenceResult], returns: InferenceResult) throws {
			let returns = returns.instantiate(in: context)

			for (arg, param) in zip(args, params) {
				let arg = arg.instantiate(in: context, with: freeVars)
				let param = param.instantiate(in: context, with: freeVars)

				try context.unify(
					replacingFreeVariable(param.type, from: freeVars),
					arg.type,
					location
				)
			}

			try context.unify(
				replacingFreeVariable(returns.type, from: freeVars),
				result,
				location
			)
		}

		private func solveStruct(type: StructType, freeVars: [TypeVariable: InferenceType]) throws {
			let instance = Instance(type: type, substitutions: freeVars)

			// Check to see if we have an initializer. If we do, unify params/args
			let initializer = initializer(for: type, freeVars: freeVars)
			if case let .function(params, _) = initializer.type {
				for (arg, param) in zip(args, params) {
					let arg = arg.instantiate(in: context, with: freeVars).type
					var param = param.instantiate(in: context, with: freeVars).type

					if case let .typeVar(variable) = param {
						param = freeVars[variable] ?? instance.substitutions[variable] ?? param
					}

					try context.unify(param, arg, location)
				}
			}

			try context.unify(.instance(.struct(instance)), result, location)
		}

		private func replacingFreeVariable(_ typeVariable: InferenceType, from variables: [TypeVariable: InferenceType]) -> InferenceType {
			if case let .typeVar(typeVar) = typeVariable {
				return variables[typeVar] ?? typeVariable
			} else {
				return typeVariable
			}
		}

		private func initializer(for type: StructType, freeVars: [TypeVariable: InferenceType]) -> InstantiatedResult {
			if let initializer = type.member(named: "init")?.instantiate(in: context, with: freeVars) {
				// We've got an init defined, just use that
				return initializer
			}

			// Need to synthesize an init
			let params: [InferenceResult] = type.members.values.compactMap {
				switch $0 {
				case .scheme:
					return nil // do nothing
				case .type(let type):
					if case .function = type {
						return nil // do nothing
					}

					return $0
				}
			}

			let instance = type.instantiate(with: freeVars)
			return .init(type: .function(params, .type(.instance(instance.wrapped))), variables: freeVars)
		}
	}
}
