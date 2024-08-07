//
//  AnalyzedFuncExpr.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

import TalkTalkSyntax

public struct AnalyzedFuncExpr: AnalyzedExpr, FuncExpr, Decl, AnalyzedDecl {
	public var type: ValueType
	let expr: FuncExpr

	public let analyzedParams: AnalyzedParamsExpr
	public let bodyAnalyzed: AnalyzedBlockExpr
	public let returnsAnalyzed: (any AnalyzedExpr)?
	public let environment: Analyzer.Environment
	public var analyzedChildren: [any AnalyzedExpr] {
		[bodyAnalyzed]
	}

	public var name: Token?
	public var funcToken: Token { expr.funcToken }
	public var params: ParamsExpr { expr.params }
	public var body: any BlockExpr { expr.body }
	public var i: Int { expr.i }
	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }

	public init(type: ValueType, expr: FuncExpr, analyzedParams: AnalyzedParamsExpr, bodyAnalyzed: AnalyzedBlockExpr, returnsAnalyzed: (any AnalyzedExpr)?, environment: Analyzer.Environment) {
		self.name = expr.name
		self.type = type
		self.expr = expr
		self.analyzedParams = analyzedParams
		self.bodyAnalyzed = bodyAnalyzed
		self.returnsAnalyzed = returnsAnalyzed
		self.environment = environment
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
