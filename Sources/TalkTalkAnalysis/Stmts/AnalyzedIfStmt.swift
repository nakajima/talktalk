// Generated by Dev/generate-type.rb 08/13/2024 10:00

import TalkTalkSyntax

public struct AnalyzedIfStmt: IfStmt, AnalyzedStmt {
	public let wrapped: IfStmtSyntax

	public var inferenceType: InferenceType
	public var environment: Environment
	public var conditionAnalyzed: any AnalyzedExpr
	public var consequenceAnalyzed: any AnalyzedExpr
	public var alternativeAnalyzed: (any AnalyzedExpr)?
	public var analyzedChildren: [any AnalyzedSyntax] {
		if let alternativeAnalyzed {
			[conditionAnalyzed, consequenceAnalyzed, alternativeAnalyzed]
		} else {
			[conditionAnalyzed, consequenceAnalyzed]
		}
	}

	// Delegate these to the wrapped node
	public var ifToken: Token { wrapped.ifToken }
	public var elseToken: Token? { wrapped.elseToken }
	public var condition: any Expr { wrapped.condition }
	public var consequence: any BlockStmt { wrapped.consequence }
	public var alternative: (any BlockStmt)? { wrapped.alternative }
	public var location: SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(wrapped, context)
	}
}
