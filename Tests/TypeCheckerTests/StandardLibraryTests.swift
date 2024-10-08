//
//  StandardLibraryTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/30/24.
//

import TalkTalkCore
import Testing
@testable import TypeChecker

struct StandardLibraryTests: TypeCheckerTest {
	@Test("Knows about array") func array() throws {
		let expr = try Parser.parse("[1, 2, 3]")
		let context = try infer(expr)
		let result = try #require(context[expr[0]])

		let instance = try #require(Instance<StructType>.extract(from: result.asType(in: context)))
		#expect(instance.type.name == "Array")
	}

	@Test("Knows about array subscript") func arraySubscript() throws {
		let expr = try Parser.parse("[1, 2, 3][0]")
		let context = try infer(expr)
		let result = try #require(context[expr[0]])

		#expect(result == .type(.base(.int)))
	}

	@Test("Knows about array as a property subscript") func arrayPropertySubscript() throws {
		let expr = try Parser.parse(
			"""
			struct Wrapper {
				var store: Array<String>
			}

			Wrapper(store: ["1"]).store[0]
			"""
		)
		let context = try infer(expr)
		let result = try #require(context[expr[1]])

		#expect(result == .type(.base(.string)))
	}

	@Test("Knows about array as a property subscript with instance element") func arrayPropertySubscriptInstanceElement() throws {
		let expr = try Parser.parse(
			"""
			struct Inner {}
			struct Wrapper {
				var store: Array<Inner>
			}

			Wrapper(store: []).store[0]
			"""
		)
		let context = try infer(expr)
		let result = try #require(context[expr[2]])

		let instance = Instance<StructType>.extract(from: result.asType(in: context))
		#expect(instance?.type.name == "Inner", "didn't get instance type, got \(result)")

//		#expect(result == .type(.base(.string)))
	}

	@Test("Knows about dictionary") func dict() throws {
		let expr = try Parser.parse("""
		["a": 123, "b": 456]
		""")
		let context = try infer(expr)
		let result = try #require(context[expr[0]])

		let instance = try #require(Instance<StructType>.extract(from: result.asType(in: context)))
		#expect(instance.type.name == "Dictionary")
	}

	@Test("Knows about dictionary subscript") func dictSubscript() throws {
		let expr = try Parser.parse("""
		let dict = ["a": 123, "b": 456]
		dict["a"]
		""")
		let context = try infer(expr)
		let result = try #require(context[expr[1]])

		#expect(result == .type(.base(.int)))
	}
}
