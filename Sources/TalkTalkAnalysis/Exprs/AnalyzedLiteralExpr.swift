//
//  AnalyzedLiteralExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct AnalyzedLiteralExpr: AnalyzedExpr, LiteralExpr {
	public var type: ValueType
	let expr: LiteralExpr
	public var analyzedChildren: [any AnalyzedExpr] { [] }
	public let environment: Analyzer.Environment

	public var value: LiteralValue { expr.value }
	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
