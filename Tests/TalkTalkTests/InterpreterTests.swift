//
//  InterpreterTests.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalk
import Testing

struct InterpreterTests {
	@Test("Evaluates literals") func literals() {
		#expect(Interpreter("1").evaluate() == .int(1))
		#expect(Interpreter("(2)").evaluate() == .int(2))
	}

	@Test("Evaluates add") func add() {
		#expect(Interpreter("(+ 1 2)").evaluate() == .int(3))
	}

	@Test("Evaluates multiple") func multiple() {
		#expect(Interpreter("""
		(def a 1)
		(def b 2)
		(+ a b)
		""").evaluate() == .int(3))
	}

	@Test("Evaluates if") func ifEval() {
		#expect(Interpreter("""
		(if true (def a 1) (def b 2))
		a
		""").evaluate() == .int(1))
	}

	@Test("Evaluates functions") func functions() {
		#expect(Interpreter("""
		(def addtwo (x in (+ x 3)))
		(addtwo 2)
		""").evaluate() == .int(5))
	}

	@Test("Evaluates calls") func calls() {
		#expect(Interpreter("""
		(call (x in (+ x 2)) 2)
		""").evaluate() == .int(4))
	}

	@Test("Evaluates counter") func counter() {
		#expect(Interpreter("""
		(
			def makeCounter (in
				(def count 0)
				(in
					(def count (+ count 1))
					count
				)
			)
		)

		(def mycounter (call makeCounter))
		(call mycounter)
		(call mycounter)
		(call mycounter)
		""").evaluate() == .int(3))
	}

	@Test("Doesn't mutate state between closures") func counter2() {
		#expect(Interpreter("""
		(
			def makeCounter (in
				(def count 0)
				(in
					(def count (+ count 1))
					count
				)
			)
		)

		(def mycounter (call makeCounter))
		(call mycounter)
		(call mycounter)

		(def urcounter (call makeCounter))
		(call urcounter)
		""").evaluate() == .int(1))
	}

	@Test("Evaluates nested scopes") func nestedScopes() {
		#expect(Interpreter("""
		(def addtwo (x in (y in (+ y x))))
		(def addfour (addtwo 4))
		(call addfour 2)
		""").evaluate() == .int(6))
	}
}
