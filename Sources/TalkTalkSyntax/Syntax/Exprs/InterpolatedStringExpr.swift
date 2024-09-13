// Generated by Dev/generate-type.rb 09/12/2024 20:43

public enum InterpolatedStringSegment {
	case string(String)
	case expr(any Expr)
}

public protocol InterpolatedStringExpr: Expr {
	// Insert InterpolatedStringExpr specific fields here
}

public struct InterpolatedStringExprSyntax: InterpolatedStringExpr {
	public var segments: [InterpolatedStringSegment]

  // A unique identifier
  public var id: SyntaxID

	// Where does this syntax live
	public var location: SourceLocation

	// Useful for just traversing the whole tree
	public var children: [any Syntax]

	// Let this node be visited by visitors
	public func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(self, context)
	}
}
