// Generated by Dev/generate-type.rb 09/04/2024 21:12

public protocol CaseStmt: Stmt {
	var patternSyntax: any Expr { get }
	var body: [any Stmt] { get }
	var isDefault: Bool { get }
	// Insert CaseStmt specific fields here
}

public struct CaseStmtSyntax: CaseStmt {
	public var caseToken: Token
	public var patternSyntax: any Expr
	public var body: [any Stmt]
	public var isDefault: Bool

  // A unique identifier
  public var id: SyntaxID

	// Where does this syntax live
	public var location: SourceLocation

	// Useful for just traversing the whole tree
	public var children: [any Syntax] {
		[patternSyntax] + body
	}

	// Let this node be visited by visitors
	public func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(self, context)
	}
}
