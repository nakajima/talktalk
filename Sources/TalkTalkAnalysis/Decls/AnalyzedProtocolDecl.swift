// Generated by Dev/generate-type.rb 08/26/2024 12:39

import TalkTalkSyntax

public struct AnalyzedProtocolDecl: ProtocolDecl, AnalyzedDecl {
	public var keywordTokenAnalyzed: Token
	public var nameAnalyzed: Token
	public var bodyAnalyzed: DeclBlockSyntax
	public let wrapped: ProtocolDeclSyntax

	public var typeID: TypeID
	public var environment: Environment
	public var analyzedChildren: [any AnalyzedSyntax] { fatalError("TODO") }

	// Delegate these to the wrapped node
	public var location: SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }
	public var keywordToken: TalkTalkSyntax.Token { wrapped.keywordToken }
	public var name: Token { wrapped.name }
	public var body: ProtocolBodyDeclSyntax { wrapped.body }
	public var typeParameters: [TypeExprSyntax] { wrapped.typeParameters }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(wrapped, context)
	}
}
