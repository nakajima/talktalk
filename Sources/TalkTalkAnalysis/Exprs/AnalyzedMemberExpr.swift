//
//  AnalyzedMemberExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct AnalyzedMemberExpr: AnalyzedExpr, MemberExpr {
	public var type: ValueType
	let expr: MemberExpr
	public var analyzedChildren: [any AnalyzedExpr] { [receiverAnalyzed] }
	public let environment: Analyzer.Environment

	public let receiverAnalyzed: any AnalyzedExpr

	public var receiver: any Expr { expr.receiver }
	public var property: String { expr.property }
	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }
	
	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
