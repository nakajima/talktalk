// Generated by Dev/generate-type.rb 08/22/2024 17:44

public protocol DictionaryLiteralExpr: Expr {
	var elements: [any DictionaryElementExpr] { get }
}

public struct DictionaryLiteralExprSyntax: DictionaryLiteralExpr {
	public var id: SyntaxID

	public var elements: [any DictionaryElementExpr]

	// Where does this syntax live
	public var location: SourceLocation

	// Useful for just traversing the whole tree
	public var children: [any Syntax] { elements }

	// Let this node be visited by visitors
	public func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(self, context)
	}
}
