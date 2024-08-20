// Generated by Dev/generate-type.rb 08/20/2024 08:16

import TalkTalkSyntax

public struct AnalyzedArrayLiteralExpr: ArrayLiteralExpr, AnalyzedExpr {
	public var environment: Environment
	public let exprsAnalyzed: [any AnalyzedExpr]

	let wrapped: any ArrayLiteralExpr

	public var typeID: TypeID
	public var analyzedChildren: [any AnalyzedSyntax] { fatalError("TODO") }

	// Delegate these to the wrapped node
	public var location: SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }
	public var exprs: [any Expr] { wrapped.exprs }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(self, context)
	}
}
