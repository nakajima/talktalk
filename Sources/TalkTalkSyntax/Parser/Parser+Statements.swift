//
//  Parser+Satments.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

extension Parser {
	mutating func ifStmt() -> any Syntax {
		let ifToken = previous!
		let i = startLocation(at: ifToken)
		let condition = expr()
		let consequence = blockExpr(false)

		var elseToken: Token?
		var alternative: (any BlockExpr)?
		if let token = match(.else) {
			elseToken = token
			alternative = blockExpr(false)
		}

		return IfStmtSyntax(
			ifToken: ifToken,
			condition: condition,
			consequence: consequence,
			elseToken: elseToken,
			alternative: alternative,
			location: endLocation(i),
			children: [condition, consequence, alternative].compactMap { $0 }
		)
	}

	mutating func importStmt() -> any Syntax {
		let importToken = previous!
		let i = startLocation(at: importToken)

		guard let name = consume(.identifier) else {
			return error(at: current, "Expected module name", expectation: .moduleName)
		}

		let module = IdentifierExprSyntax(name: name.lexeme, location: [name])
		return ImportStmtSyntax(token: importToken, module: module, location: endLocation(i))
	}
}
