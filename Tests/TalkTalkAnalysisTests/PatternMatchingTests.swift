//
//  PatternMatchingTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/6/24.
//

import TalkTalkAnalysis
import TalkTalkCore
import TalkTalkCore
import Testing
@testable import TypeChecker

struct PatternMatchingTests: AnalysisTest {
	@Test("Can analyze an enum") func enumStmt() async throws {
		let ast = try await ast("""
		enum Thing {
			case foo(String)
			case bar(int)
		}
		""")

		let decl = ast.cast(AnalyzedEnumDecl.self)
		#expect(decl.nameToken.lexeme == "Thing")
		#expect(decl.casesAnalyzed.count == 2)

		#expect(decl.casesAnalyzed[0].nameToken.lexeme == "foo")
		#expect(decl.casesAnalyzed[1].nameToken.lexeme == "bar")

		#expect(decl.casesAnalyzed[0].attachedTypesAnalyzed[0].inferenceType == .base(.string))
		#expect(decl.casesAnalyzed[1].attachedTypesAnalyzed[0].inferenceType == .base(.int))
	}

	@Test("Errors when match is not exhaustive (enums)") func exhaustiveEnum() async throws {
		let ast = try await ast("""
		enum Thing {
			case foo(String)
			case bar(int)
		}

		match Thing.foo("sup") {
		case .foo(let string):
			print(string)
		}
		""")

		let errors = ast.collectErrors()
		#expect(errors.count == 1)
		#expect(errors[0].kind == .matchNotExhaustive("Match not exhaustive. Missing bar"))
	}

	@Test("Errors when match is not exhaustive (non-enums)") func exhaustiveNonEnums() async throws {
		let ast = try await ast("""
		match "foo" {
		case "sup":
			print("hi")
		}
		""")

		let errors = ast.collectErrors()
		#expect(errors.count == 1)
		#expect(errors[0].kind == .matchNotExhaustive("Match not exhaustive."))
	}

	@Test("Doesnt error when match is exhaustive (bools)") func exhaustiveBools() async throws {
		let ast = try await ast("""
		let variable = true

		match variable {
		case true:
			print("hi")
		case false:
			print("hi")
		}
		""")

		let errors = ast.collectErrors()
		#expect(errors.count == 0)
	}

	@Test("Doesnt error when not exhaustive with else (enums)") func enumWithElse() async throws {
		let ast = try await ast("""
		enum Thing {
			case foo(String)
			case bar(int)
		}

		match Thing.foo("sup") {
		case .foo(let string):
			print(string)
		else:
			print("it's ok")
		}
		""")

		let errors = ast.collectErrors()
		#expect(errors == [])
	}

	@Test("Can analyze a match statement") func matchStatement() async throws {
		let asts = try await asts("""
		enum Thing {
			case foo(String)
			case bar(int)
		}

		match Thing.bar(123) {
		case .foo(let a):
			a
		case .bar(let a):
			a
		}
		""")

		let enumType = EnumType.extract(from: .type(asts[0].typeAnalyzed))!

		let stmt = asts[1].cast(AnalyzedMatchStatement.self)
		let foo = stmt.casesAnalyzed[0].patternAnalyzed!
		#expect(foo.inferenceType == .pattern(
			Pattern(
				type: .enumCase(EnumCase(
					type: enumType,
					name: "foo",
					attachedTypes: [.base(.string)]
				)),
				arguments: [.variable("a", .type(.base(.string)))]
			)
		))

		let bar = stmt.casesAnalyzed[1].patternAnalyzed!
		#expect(bar.inferenceType == .pattern(
			Pattern(
				type: .enumCase(EnumCase(
					type: enumType,
					name: "bar",
					attachedTypes: [.base(.int)]
				)),
				arguments: [.variable("a", .type(.base(.int)))]
			)
		))
	}
}
