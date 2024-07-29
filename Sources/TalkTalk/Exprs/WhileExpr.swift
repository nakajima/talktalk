//
//  WhileExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/28/24.
//

public protocol WhileExpr: Expr {
	var condition: any Expr { get }
	var body: any BlockExpr { get }
}

public struct WhileExprSyntax: WhileExpr {
	public var condition: any Expr
	public var body: any BlockExpr

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V : Visitor {
		visitor.visit(self, scope)
	}
}
