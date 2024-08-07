//
//  AnalyzedErrorExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct AnalyzedErrorSyntax: AnalyzedExpr, ErrorSyntax {
	public var type: ValueType
	let expr: any ErrorSyntax
	public var analyzedChildren: [any AnalyzedExpr] { [] }
	public let environment: Analyzer.Environment

	public var message: String { expr.message }
	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }
	public var expectation: ParseExpectation { expr.expectation }

	public init(type: ValueType, expr: any ErrorSyntax, environment: Analyzer.Environment) {
		self.type = type
		self.expr = expr
		self.environment = environment
		print(message)
	}

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
