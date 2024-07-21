//
//  Expr.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public protocol Expr: Syntax, Hashable {}

public extension Expr {
	func accept<Visitor>(_: inout Visitor, context _: Visitor.Context) -> Visitor.Value where Visitor: ASTVisitor {
		fatalError("Unimplemented visitor")
	}
}