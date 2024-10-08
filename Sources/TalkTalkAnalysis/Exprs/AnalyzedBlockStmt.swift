//
//  AnalyzedBlockStmt.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/28/24.
//

import TalkTalkCore

public struct AnalyzedBlockStmt: AnalyzedExpr, BlockStmt {
	public let wrapped: BlockStmtSyntax
	public let inferenceType: InferenceType

	public var stmtsAnalyzed: [any AnalyzedSyntax]
	public var analyzedChildren: [any AnalyzedSyntax] { stmtsAnalyzed }
	public let environment: Environment

	public var stmts: [any Stmt] { wrapped.stmts }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(wrapped, scope)
	}
}
