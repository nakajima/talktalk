//
//  Infix.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/1/24.
//

import TalkTalkCore

extension Constraints {
	struct Infix: Constraint {
		let context: Context
		let lhs: InferenceResult
		let rhs: InferenceResult
		let op: BinaryOperator
		let result: TypeVariable
		let location: SourceLocation
		var retries: Int = 0

		var before: String {
			"Infix(lhs: \(lhs.debugDescription), rhs: \(rhs.debugDescription), op: \(op), result: \(result.debugDescription))"
		}

		var after: String {
			let lhs = context.applySubstitutions(to: lhs)
			let rhs = context.applySubstitutions(to: rhs)
			let result = context.applySubstitutions(to: .type(.typeVar(result)))

			return "Infix(lhs: \(lhs.debugDescription), rhs: \(rhs.debugDescription), op: \(op), result: \(result.debugDescription))"
		}

		func solve() {
			let lhs = context.applySubstitutions(to: lhs)
			let rhs = context.applySubstitutions(to: rhs)

			// Default rules for primitive types
			switch (lhs, rhs, op) {
			case (.base(.pointer), .base(.int), .plus),
				(.base(.pointer), .base(.int), .minus):

				context.unify(.type(.typeVar(result)), .type(.base(.pointer)), location)
			case (.base(.int), .base(.int), .plus),
					 (.base(.int), .base(.int), .minus),
					 (.base(.int), .base(.int), .star),
					 (.base(.int), .base(.int), .slash):

				context.unify(.type(.typeVar(result)), .type(.base(.int)), location)
			case let (.base(.int), .typeVar(variable), .plus),
				let (.base(.int), .typeVar(variable), .minus),
				let (.base(.int), .typeVar(variable), .star),
				let (.base(.int), .typeVar(variable), .slash),
				let (.base(.int), .typeVar(variable), .less),
				let (.base(.int), .typeVar(variable), .lessEqual),
				let (.base(.int), .typeVar(variable), .greater),
				let (.base(.int), .typeVar(variable), .greaterEqual),
				let (.typeVar(variable), .base(.int), .plus),
				let (.typeVar(variable), .base(.int), .minus),
				let (.typeVar(variable), .base(.int), .star),
				let (.typeVar(variable), .base(.int), .slash),
				let (.typeVar(variable), .base(.int), .less),
				let (.typeVar(variable), .base(.int), .lessEqual),
				let (.typeVar(variable), .base(.int), .greater),
				let (.typeVar(variable), .base(.int), .greaterEqual):

				context.unify(.type(.typeVar(variable)), .type(.base(.int)), location)
				context.unify(.type(.typeVar(result)), .type(.base(.int)), location)
			case (.base(.string), (.base(.string)), .plus):
				context.unify(.type(.typeVar(result)), .type(.base(.string)), location)
			case let (.typeVar(lhs), .typeVar(rhs), _):
				// Just say that it's the same as the result and hope for the best
				context.unify(.type(.typeVar(lhs)), .type(.typeVar(result)), location)
				context.unify(.type(.typeVar(rhs)), .type(.typeVar(result)), location)
			default:
				context.error("Infix operator \(op.rawValue) can't be used with operands \(lhs.debugDescription) and \(rhs.debugDescription)", at: location)
				context.unify(.type(.any), .type(.typeVar(result)), location)
			}
		}
	}
}