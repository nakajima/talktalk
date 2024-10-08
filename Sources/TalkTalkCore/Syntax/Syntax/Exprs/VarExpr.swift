//
//  VarExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public protocol VarExpr: Expr {
	var token: Token { get }
	var name: String { get }
}

public struct VarExprSyntax: VarExpr {
	public var id: SyntaxID
	public let token: Token
	public let location: SourceLocation
	public var children: [any Syntax] { [] }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(self, scope)
	}

	public init(id: SyntaxID, token: Token, location: SourceLocation) {
		self.id = id
		self.token = token
		self.location = location
	}

	public var name: String {
		token.lexeme
	}
}
