// Generated by Dev/generate-type.rb 08/13/2024 10:00

public protocol IfStmt: Stmt {
	// Insert IfStmt specific fields here
}

public struct IfStmtSyntax: IfStmt {
	// Where does this syntax live
	public var location: SourceLocation

	// Useful for just traversing the whole tree
	public var children: [any Syntax]

	// Let this node be visited by visitors
	public func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(self, context)
	}
}
