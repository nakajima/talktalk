//
//  AnalyzedStructExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/30/24.
//

import TalkTalkSyntax

public struct AnalyzedStructExpr: AnalyzedExpr, StructExpr {
	public var type: ValueType
	let expr: StructExpr

	public let bodyAnalyzed: AnalyzedDeclBlock
	public let properties: [String: Property]
	public let methods: [String: Property]

	public var name: String? { expr.name }
	public var body: DeclBlockExpr { expr.body }
	public var location: SourceLocation { expr.location }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) -> V.Value {
		visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: AnalyzedVisitor {
		visitor.visit(self, scope)
	}
}
