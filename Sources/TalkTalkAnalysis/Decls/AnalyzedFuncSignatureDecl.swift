// Generated by Dev/generate-type.rb 08/26/2024 13:05

import TalkTalkCore

public struct AnalyzedFuncSignatureDecl: FuncSignatureDecl, AnalyzedDecl {
	public let wrapped: FuncSignatureDeclSyntax

	public var inferenceType: InferenceType
	public var environment: Environment
	public var analyzedChildren: [any AnalyzedSyntax] {
		[]
	}

	// Delegate these to the wrapped node
	public var location: SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(wrapped, context)
	}
}
