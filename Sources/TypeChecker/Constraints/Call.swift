//
//  Call.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/1/24.
//

import TalkTalkCore

extension Constraints {
	struct Call: Constraint {
		let context: Context
		let callee: InferenceResult
		let args: [InferenceResult]
		let result: InferenceResult
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
			let callee = context.applySubstitutions(to: .type(result.type), with: result.variables)

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

		private func solveFunction(callee: InferenceType, freeVars: [TypeVariable: InferenceResult], params: [InferenceResult], returns: InferenceResult) throws {
			for (arg, param) in zip(args, params) {
				if case let .type(.typeVar(typeVar)) = param {
					try context.unify(freeVars[typeVar] ?? param, arg, location)
				} else {
					try context.unify(param, arg, location)
				}
			}

			if case let .type(.typeVar(typeVar)) = returns {
				try context.unify(freeVars[typeVar] ?? returns, result, location)
			} else {
				try context.unify(returns, result, location)
			}
		}

		private func solveStruct(type: StructType, freeVars: [TypeVariable: InferenceResult]) throws {
			let instance = Instance(type: type, substitutions: freeVars)

			// Check to see if we have an initializer. If we do, unify params/args
			if let initializer = type.member(named: "init")?.instantiate(in: context),
				 case let .function(params, _) = initializer.type {
				for (arg, var param) in zip(args, params) {
					if case let .typeVar(variable) = context.applySubstitutions(to: param) {
						param = instance.substitutions[variable] ?? param
					}

					try context.unify(param, arg, location)
				}
			}

			try context.unify(.type(.instance(.struct(instance))), result, location)
		}

		private func replacingFreeVariable(_ typeVariable: InferenceResult, from variables: [TypeVariable: InferenceResult]) -> InferenceResult {
			if case let .type(.typeVar(typeVar)) = typeVariable {
				return variables[typeVar] ?? typeVariable
			} else {
				return typeVariable
			}
		}
	}
}
