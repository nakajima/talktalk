//
//  AnalyzedDefExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct AnalyzedDefExpr: AnalyzedExpr, DefExpr {
	public var type: ValueType
	let expr: DefExpr

	public var name: Token { expr.name }
	public var value: any Expr { expr.value }
	public var location: SourceLocation { expr.location }

	public var valueAnalyzed: any AnalyzedExpr

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) -> V.Value {
		visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: AnalyzedVisitor {
		visitor.visit(self, scope)
	}
}
