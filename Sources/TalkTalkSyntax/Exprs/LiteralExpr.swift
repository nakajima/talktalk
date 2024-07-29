//
//  LiteralExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public enum LiteralValue: Equatable {
	case int(Int), bool(Bool), none
}

public protocol LiteralExpr: Expr {
	var value: LiteralValue { get }
}

public struct LiteralExprSyntax: LiteralExpr {
	public let value: LiteralValue

	public init(value: LiteralValue) {
		self.value = value
	}

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) -> V.Value {
		visitor.visit(self, scope)
	}
}