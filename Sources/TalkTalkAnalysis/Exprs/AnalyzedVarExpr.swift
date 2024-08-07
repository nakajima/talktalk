//
//  AnalyzedVarExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct AnalyzedVarExpr: AnalyzedExpr, AnalyzedDecl, VarExpr {
	public var type: ValueType
	let expr: VarExpr
	public var analyzedChildren: [any AnalyzedExpr] { [] }
	public let environment: Analyzer.Environment

	public var token: Token { expr.token }
	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(self, scope)
	}

	public var name: String {
		token.lexeme
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
