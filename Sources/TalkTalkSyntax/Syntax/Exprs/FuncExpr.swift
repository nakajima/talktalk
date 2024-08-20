//
//  FuncExpr.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

public protocol FuncExpr: Expr {
	var funcToken: Token { get }
	var params: ParamsExpr { get }
	var body: any BlockStmt { get }
	var typeDecl: (any TypeExpr)? { get }
	var i: Int { get }
	var name: Token? { get }
}

public extension FuncExpr {
	var autoname: String {
		"_fn_\(params.params.map(\.name).joined(separator: "_"))_\(i)"
	}
}

public struct FuncExprSyntax: FuncExpr, Decl {
	public let funcToken: Token
	public let typeDecl: (any TypeExpr)?
	public let params: ParamsExpr
	public let body: any BlockStmt
	public let i: Int
	public let name: Token?
	public let location: SourceLocation
	public var children: [any Syntax] { [params, body] }

	public init(funcToken: Token, params: ParamsExpr, typeDecl: (any TypeExpr)?, body: any BlockStmt, i: Int, name: Token? = nil, location: SourceLocation) {
		self.funcToken = funcToken
		self.params = params
		self.typeDecl = typeDecl
		self.body = body
		self.i = i
		self.name = name // ??
		self.location = location
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}
}
