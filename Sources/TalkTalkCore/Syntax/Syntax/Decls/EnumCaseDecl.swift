// Generated by Dev/generate-type.rb 09/04/2024 18:30

public protocol EnumCaseDecl: Decl {
	// Insert EnumCaseDecl specific fields here
	var nameToken: Token { get }
	var attachedTypes: [TypeExpr] { get }
}

public struct EnumCaseDeclSyntax: EnumCaseDecl {
	public var caseToken: Token
	public var nameToken: Token
	public var attachedTypes: [TypeExpr]

	// A unique identifier
	public var id: SyntaxID

	// Where does this syntax live
	public var location: SourceLocation

	// Useful for just traversing the whole tree
	public var children: [any Syntax] {
		attachedTypes
	}

	// Let this node be visited by visitors
	public func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(self, context)
	}
}
