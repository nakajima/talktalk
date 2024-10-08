// Generated by Dev/generate-type.rb 09/04/2024 21:41

public protocol EnumMemberExpr: Expr {
	// Insert EnumMemberExpr specific fields here
}

public struct EnumMemberExprSyntax: EnumMemberExpr {
	public var receiver: IdentifierExprSyntax?
	public var property: Token
	public var params: [ParamSyntax]

	// A unique identifier
	public var id: SyntaxID

	// Where does this syntax live
	public var location: SourceLocation

	// Useful for just traversing the whole tree
	public var children: [any Syntax] {
		if let receiver {
			[receiver] + params
		} else {
			params
		}
	}

	// Let this node be visited by visitors
	public func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(self, context)
	}
}
