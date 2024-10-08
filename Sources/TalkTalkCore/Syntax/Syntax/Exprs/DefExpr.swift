//
//  DefExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public protocol DefExpr: Expr {
	var receiver: any Expr { get }
	var value: any Expr { get }
	var op: Token { get }
}

public struct DefExprSyntax: DefExpr {
	public var id: SyntaxID
	public let receiver: any Expr
	public let value: any Expr
	public let op: Token
	public let location: SourceLocation
	public var children: [any Syntax] { [receiver, value] }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(self, scope)
	}
}
