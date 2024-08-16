@testable import TalkTalkSyntax
import Testing

struct TalkTalkLexerTests {
	@Test("Int") func int() {
		var lexer = TalkTalkLexer("1")
		let tokens = lexer.collect()

		#expect(tokens.map(\.kind) == [
			.int,
			.eof,
		])

		#expect(tokens.map(\.line) == [
			0,
			0,
		])
	}

	@Test("Import") func importing() {
		var lexer = TalkTalkLexer("import Test")
		let tokens = lexer.collect()
		#expect(tokens.map(\.kind) == [
			.import,
			.identifier,
			.eof
		])
	}

	@Test("Symbols and ints and parens") func symbolsAndInts() async throws {
		var lexer = TalkTalkLexer("10 ^ 20")
		let tokens = lexer.collect()

		#expect(tokens.map(\.kind) == [
			.int,
			.symbol,
			.int,
			.eof,
		])

		#expect(tokens.map(\.column) == [
			0,
			3,
			5,
			7,
		])
	}

	@Test("Strings") func strings() throws {
		var lexer = TalkTalkLexer(#""hello world""#)
		let tokens = lexer.collect()
		#expect(tokens.map(\.kind) == [
			.string,
			.eof,
		])

		#expect(tokens[0].length == 13)
	}

	@Test("Floats") func floats() async throws {
		var lexer = TalkTalkLexer("1.23")
		let token = lexer.collect()[0]
		#expect(token.kind == .float)
		#expect(token.lexeme == "1.23")
	}

	@Test("Identifier") func identifier() async throws {
		var lexer = TalkTalkLexer("foo12")
		let token = lexer.collect()[0]
		#expect(token.kind == .identifier)
		#expect(token.lexeme == "foo12")
	}

	@Test("Identifier starting with underscore") func identifierUnderscore() async throws {
		var lexer = TalkTalkLexer("_foo12")
		let token = lexer.collect()[0]
		#expect(token.kind == .identifier)
		#expect(token.lexeme == "_foo12")
	}

	@Test("eof") func eof() async throws {
		var lexer = TalkTalkLexer("()")
		let tokens = lexer.collect()

		#expect(tokens[0].kind == .leftParen)
		#expect(tokens[0].lexeme == "(")

		#expect(tokens[1].kind == .rightParen)
		#expect(tokens[1].lexeme == ")")

		#expect(tokens[2].kind == .eof)
		#expect(tokens[2].lexeme == "EOF")
	}

	@Test("equals") func equals() throws {
		var lexer = TalkTalkLexer("foo = 123")
		let tokens = lexer.collect()

		#expect(tokens.map(\.kind) == [
			.identifier,
			.equals,
			.int,
			.eof
		])
	}

	@Test("anon func") func anonfunction() throws {
		var lexer = TalkTalkLexer("func(x, y) { 10 }")
		let tokens = lexer.collect()

		#expect(tokens.map(\.kind) == [
			.func,
			.leftParen,
			.identifier,
			.comma,
			.identifier,
			.rightParen,
			.leftBrace,
			.int,
			.rightBrace,
			.eof
		])
	}

	@Test("Comments") func comments() async throws {
		var lexer = TalkTalkLexer("""
		// This is a comment
		func foo() {
			10
		}
		""")
		let tokens = lexer.collect()
		#expect(tokens.map(\.kind) == [
			.newline,
			.func,
			.identifier,
			.leftParen,
			.rightParen,
			.leftBrace,
			.newline,
			.int,
			.newline,
			.rightBrace,
			.eof
		])

		#expect(tokens.map(\.line) == [
			1,
			1,
			1,
			1,
			1,
			1,
			2,
			2,
			3,
			3,
			3
		])
	}

	@Test("Columns") func columns() {
		var lexer = TalkTalkLexer(
//			"""
//			struct Person {
//				func greet() {
//					print("sup")
//				}
//			}
//
//			person = Person()
//			person.greet()
//			"""
			"""
			123
			456
			"""
		)

		let tokens = lexer.collect()
		#expect(tokens.map(\.kind) == [
			.int,
			.newline,
			.int,
			.eof
		])

		#expect(tokens.map(\.line) == [
			0,
			0,
			1,
			1
		])

		#expect(tokens.map(\.column) == [
			0,
			3,
			0,
			3
		])
	}

	@Test("func") func function() async throws {
		var lexer = TalkTalkLexer("""
		func foo() {
			10
		}
		""")
		let tokens = lexer.collect()

		#expect(tokens.map(\.kind) == [
			.func,
			.identifier,
			.leftParen,
			.rightParen,
			.leftBrace,
			.newline,
			.int,
			.newline,
			.rightBrace,
			.eof
		])

		#expect(tokens.map(\.line) == [
			0,
			0,
			0,
			0,
			0,
			1,
			1,
			2,
			2,
			2
		])
	}

	@Test("while") func whilekeyword() {
		var lexer = TalkTalkLexer("while { }")
		let tokens = lexer.collect()

		#expect(tokens.map(\.kind) == [
			.while,
			.leftBrace,
			.rightBrace,
			.eof
		])
	}

	@Test("newline collapsing") func newline() async throws {
		var lexer = TalkTalkLexer("""


		""")
		let tokens = lexer.collect()
		#expect(tokens.count == 2)
		#expect(tokens[0].kind == .newline)
		#expect(tokens[1].kind == .eof)
	}
}
