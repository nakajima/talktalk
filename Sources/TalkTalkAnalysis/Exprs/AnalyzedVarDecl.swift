//
//  AnalyzedVarDecl.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/30/24.
//

import TalkTalkSyntax

public struct AnalyzedVarDecl: AnalyzedExpr, AnalyzedDecl, VarDecl {
	public var type: ValueType
	let expr: VarDecl

	public var name: String { expr.name }
	public var typeDecl: String { expr.typeDecl }
	public var location: SourceLocation { expr.location }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) -> V.Value {
		visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: AnalyzedVisitor {
		visitor.visit(self, scope)
	}
}