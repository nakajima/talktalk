//
//  AnalyzedReturnExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/31/24.
//

import TalkTalkSyntax

public struct AnalyzedReturnStmt: AnalyzedStmt, ReturnStmt {
	public let typeID: TypeID
	public var analyzedChildren: [any AnalyzedSyntax] {
		if let valueAnalyzed { [valueAnalyzed] } else { [] }
	}

	public let environment: Environment

	let expr: any ReturnStmt

	public var returnToken: Token { expr.returnToken }
	public var value: (any Expr)? { expr.value }
	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }

	public var valueAnalyzed: (any AnalyzedExpr)?

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}