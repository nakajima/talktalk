//
//  AnalyzedErrorExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkBytecode
import TalkTalkCore

public struct AnalyzedErrorSyntax: AnalyzedExpr, ParseError, Member {
	public var expr: any Syntax { wrapped }

	public var symbol: Symbol = .struct("[error]", "error")
	public var name: String = ""
	public var isMutable: Bool = false

	public let inferenceType: InferenceType
	public let wrapped: ParseErrorSyntax
	public var analyzedChildren: [any AnalyzedSyntax] { [] }
	public let environment: Environment

	public var message: String { wrapped.message }
	public var expectation: ParseExpectation { wrapped.expectation }
	public var isStatic = false

	public init(typeID: InferenceType, wrapped: ParseErrorSyntax, environment: Environment) {
		self.inferenceType = typeID
		self.wrapped = wrapped
		self.environment = environment
	}

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(wrapped, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
