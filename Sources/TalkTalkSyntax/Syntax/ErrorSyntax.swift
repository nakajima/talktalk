//
//  ErrorSyntax.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

// This is sorta leaking semantic info into the syntax package but also the parser knows
// a bunch of stuff that we probably don't want to leak _out_ of the syntax package?
public enum ParseExpectation {
	case decl, expr, identifier, none, type, variable, member

	static func guess(from kind: Token.Kind) -> ParseExpectation {
		switch kind {
		case .identifier:
			.identifier
		default:
			.none
		}
	}
}

public protocol ErrorSyntax: Decl, Expr, Syntax {
	var message: String { get }
	var expectation: ParseExpectation { get }
}

public struct SyntaxError: ErrorSyntax {
	public let location: SourceLocation
	public let message: String
	public var children: [any Syntax] { [] }
	public var expectation: ParseExpectation

	public init(location: SourceLocation, message: String, expectation: ParseExpectation) {
		self.location = location
		self.message = message
		self.expectation = expectation
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : Visitor {
		try visitor.visit(self, scope)
	}
}
