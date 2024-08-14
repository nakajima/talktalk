//
//  REPLTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/14/24.
//

import Testing
import TalkTalkVM

struct REPLTests {
	@Test("Basic") func basic() async throws {
		var repl = try await REPLRunner()

		try #expect(repl.evaluate("123", index: 0).get() == .int(123))
	}

	@Test("Global vars") func globals() async throws {
		var repl = try await REPLRunner()

		_ = try repl.evaluate("var a = 10", index: 0)
		try #expect(repl.evaluate("a + 20", index: 1).get() == .int(30))
	}
}
