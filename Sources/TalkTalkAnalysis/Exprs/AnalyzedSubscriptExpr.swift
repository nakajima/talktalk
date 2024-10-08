// Generated by Dev/generate-type.rb 08/20/2024 09:32

import TalkTalkBytecode
import TalkTalkCore

public struct AnalyzedSubscriptExpr: SubscriptExpr, AnalyzedExpr {
	public var receiverAnalyzed: any AnalyzedExpr
	public var argsAnalyzed: [AnalyzedArgument]
	public let getSymbol: Symbol

	public let wrapped: SubscriptExprSyntax

	public var inferenceType: InferenceType
	public var environment: Environment
	public var analysisErrors: [AnalysisError]
	public var analyzedChildren: [any AnalyzedSyntax] { [receiverAnalyzed] + argsAnalyzed.map(\.expr) }

	// Delegate these to the wrapped node
	public var receiver: any Expr { wrapped.receiver }
	public var location: SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }
	public var args: [Argument] { wrapped.args }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(wrapped, context)
	}
}
