// Generated by Dev/generate-type.rb 09/04/2024 21:04

public protocol MatchStatement: Stmt {
	// Insert MatchStatement specific fields here
}

public struct MatchStatementSyntax: MatchStatement {
	public var matchToken: Token
	public var target: any Expr
	public var cases: [CaseStmt]

	// A unique identifier
	public var id: SyntaxID

	// Where does this syntax live
	public var location: SourceLocation

	// Useful for just traversing the whole tree
	public var children: [any Syntax] {
		[target] + cases
	}

	// Let this node be visited by visitors
	public func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(self, context)
	}
}
