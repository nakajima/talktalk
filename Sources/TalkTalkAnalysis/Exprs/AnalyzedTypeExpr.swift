//
//  AnalyzedTypeExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/11/24.
//

import TalkTalkBytecode
import TalkTalkCore

public struct AnalyzedTypeExpr: TypeExpr, AnalyzedExpr {
	public let wrapped: TypeExprSyntax

	public let symbol: Symbol
	public let inferenceType: InferenceType
	public var analyzedChildren: [any AnalyzedSyntax] { [] }
	public var environment: Environment

	public var identifier: Token { wrapped.identifier }
	public var genericParams: [TypeExprSyntax] { wrapped.genericParams }
	public var location: SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }
	public var isOptional: Bool { wrapped.isOptional }

	public func accept<V>(_ visitor: V, _ context: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(wrapped, context)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
