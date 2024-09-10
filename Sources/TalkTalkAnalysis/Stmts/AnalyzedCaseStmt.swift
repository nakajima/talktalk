// Generated by Dev/generate-type.rb 09/04/2024 21:12

import TalkTalkSyntax
import TypeChecker

public struct AnalyzedCaseStmt: CaseStmt, AnalyzedStmt {
  public let wrapped: CaseStmtSyntax
	public var patternAnalyzed: any AnalyzedExpr
	public var bodyAnalyzed: [any AnalyzedStmt]
	public var pattern: InferenceType

	public var inferenceType: InferenceType
	public var environment: Environment
	public var analyzedChildren: [any AnalyzedSyntax] {
		bodyAnalyzed + [patternAnalyzed]
	}

	// Delegate these to the wrapped node
	public var isDefault: Bool { wrapped.isDefault }
	public var body: [any Stmt] { wrapped.body }
	public var location: SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }
	public var patternSyntax: any Expr { wrapped.patternSyntax }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(wrapped, context)
	}
}
