//
//  SemanticTokensTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

import Testing
import TalkTalkSyntax
import TalkTalkAnalysis
@testable import TalkTalkLSP

struct SemanticTokensTests {
	@Test("Finds tokens") func basic() throws {
		let string = """

		person = "Pat"
		pet = "dog"

		func foo() {}

		print("hi")
		"""

		let analyzed = try Analyzer.analyze(Parser.parse(string))
		let visitor = SemanticTokensVisitor()
		let tokens = RelativeSemanticToken.generate(from: try analyzed.accept(visitor, .topLevel))

		#expect(tokens == [
			RelativeSemanticToken(lineDelta: 1, startDelta: 0, length: 6, tokenType: .variable, modifiers: [], lexeme: "person"),
			RelativeSemanticToken(lineDelta: 0, startDelta: 9, length: 5, tokenType: .string, modifiers: [], lexeme: "\"Pat\""),
			RelativeSemanticToken(lineDelta: 1, startDelta: 0, length: 3, tokenType: .variable, modifiers: [], lexeme: "pet"),
			RelativeSemanticToken(lineDelta: 0, startDelta: 6, length: 5, tokenType: .string, modifiers: [], lexeme: "\"dog\""),
			RelativeSemanticToken(lineDelta: 2, startDelta: 0, length: 4, tokenType: .keyword, modifiers: [], lexeme: "func"),
			RelativeSemanticToken(lineDelta: 0, startDelta: 5, length: 3, tokenType: .function, modifiers: [], lexeme: "foo"),
			RelativeSemanticToken(lineDelta: 2, startDelta: 0, length: 5, tokenType: .variable, modifiers: [], lexeme: "print"),
			RelativeSemanticToken(lineDelta: 0, startDelta: 6, length: 4, tokenType: .string, modifiers: [], lexeme: "\"hi\""),
		])
	}
}
