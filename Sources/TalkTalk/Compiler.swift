//
//  Compiler.swift
//
//
//  Created by Pat Nakajima on 7/1/24.
//
public class Compiler {
	enum Errors: Swift.Error {
		case errors([Error])
	}

	struct Error {
		var token: Token?
		var message: String

		var description: String {
			if let token {
				"Compiler Error: \(message) at \(token)"
			} else {
				"Compiler Error: \(message)"
			}
		}
	}

	var parent: Compiler?
	var parser: Parser
	var currentFunction: Function
	var errors: [Error] = []

	// MARK: Local variable management
	var locals = ContiguousArray<Local?>(repeating: nil, count: 256)
	var localCount = 1 // Reserve local count spot 0 for internal use
	var scopeDepth = 0
	var upvalues: [Upvalue] = []

	// MARK: Debuggy

	#if DEBUG
		var parserRepeats: [Int: Int] = [:]

		func checkForInfiniteLoop() {
			parserRepeats[parser.current.start, default: 0] += 1

			if parserRepeats[parser.current.start]! > 100 {
				fatalError("Probably an infinite loop goin pat.")
			}
		}
	#endif

	init(parent: Compiler) {
		self.parent = parent
		self.parser = parent.parser
		self.currentFunction = Function(arity: 0, chunk: Chunk(), name: "")
		self.locals[0] = Local(name: parser.current, depth: 0)
	}

	public init(source: String) {
		self.parser = Parser(lexer: Lexer(source: source))
		self.currentFunction = Function(arity: 0, chunk: Chunk(), name: "main", kind: .main)
		self.locals[0] = Local(name: parser.current, depth: 0)
	}

	var compilingChunk: Chunk {
		currentFunction.chunk
	}

	var source: ContiguousArray<Character> {
		parser.lexer.source
	}

	public func compile() throws {
		while parser.current.kind != .eof {
			declaration()

			#if DEBUG
				checkForInfiniteLoop()
			#endif
		}

		if errors.isEmpty {
			emit(opcode: .nil, "Final function nil return")
			emit(opcode: .return, "Final function return")
			return
		}

		throw Errors.errors(errors)
	}

	func declaration() {
		if parser.match(.func) {
			funcDeclaration()
		} else if parser.match(.var) {
			varDeclaration()
		} else {
			statement()
		}
	}

	func funcDeclaration() {
		let global = parseVariable("Expected function name.")
		markInitialized()
		function(.function)
		defineVariable(global: global)
	}

	func varDeclaration() {
		let global = parseVariable("Expected variable name")

		defer {
			defineVariable(global: global)
		}

		if parser.match(.equal) {
			expression()
		} else {
			emit(opcode: .nil, "Default nil return variable")
		}

		parser.consume(.semicolon, "Expected ';' after variable declaration")
	}

	// MARK: Statements

	func block() {
		while !parser.check(.rightBrace), !parser.check(.eof) {
			declaration()
		}

		parser.consume(.rightBrace, "Expected '}' after block.")
	}

	func expression() {
		parse(precedence: .assignment)
	}

	func parseVariable(_ message: String) -> Byte {
		parser.consume(.identifier, message)

		declareVariable()

		if scopeDepth > 0 {
			return 0
		}

		return identifierConstant(parser.previous)
	}

	// Starting with parser.current, parse expressions at `precedence`
	// level or higher.
	func parse(precedence: Parser.Precedence) {
		parser.advance()

		let opKind = parser.previous.kind
		let rule = opKind.rule

		guard let prefix = rule.prefix else {
			error("Expected expression at line \(parser.previous.line).")
			return
		}

		let canAssign = precedence <= .assignment
		prefix(self, canAssign)

		while precedence < parser.current.kind.rule.precedence {
			#if DEBUG
			checkForInfiniteLoop()
			#endif

			parser.advance()

			if let infix = parser.previous.kind.rule.infix {
				infix(self, canAssign)
			}

			if canAssign, parser.match(.equal) {
				error("Syntax Error: Invalid target assignment", at: parser.previous)
			}
		}
	}

	func uint16ToBytes(_ uint16: Int) -> (Byte, Byte) {
		let a = (uint16 >> 8) & 0xFF
		let b = (uint16 & 0xFF)

		return (Byte(a), Byte(b))
	}

	// MARK: Emitters

	func emit(loop backToInstruction: Int) {
		emit(opcode: .loop, "Jump loop opcode")

		let offset = compilingChunk.count - backToInstruction + 2
		if offset > UInt16.max {
			error("Loop body too large, cmon.")
		}

		let (a, b) = uint16ToBytes(offset)
		emit(a, b, "Loop jump bytes")
	}

	func emit(jump instruction: Opcode) -> Int {
		emit(opcode: instruction, "Emitting jump")

		// Use two bytes for the offset, which lets us jump over 65k bytes of code.
		// We'll fill these in with the patchJump later.
		emit(opcode: .uninitialized, "Jump placeholder 1")
		emit(opcode: .uninitialized, "Jump placeholder 2")

		// Return the current location of our chunk code, offset by 2 (since that's
		// where we're gonna store our offset.
		return compilingChunk.count - 2
	}

	func patchJump(_ offset: Int) {
		// -2 to adjust for the bytecode for the jump offset itself
		let jump = compilingChunk.count - offset - 2
		if jump > UInt16.max {
			error("Too much code to jump over")
		}

		// Go back and replace the two placeholder bytes from emit(jump:)
		// the actual offset to jump over.
		let (a, b) = uint16ToBytes(jump)
		compilingChunk.code[offset] = a
		compilingChunk.code[offset + 1] = b
	}

	func emit(constant value: Value, _ message: String) {
		if compilingChunk.constants.count > UInt8.max {
			error("Too many constants in one chunk")
			return
		}

		compilingChunk.write(value: value, line: parser.previous?.line ?? -1)
	}

	func emit(opcode: Opcode, _ message: String) {
		emit(opcode.byte, message)
	}

	func emit(_ opcode1: Opcode, _ opcode2: Opcode, _ message: String) {
		emit(opcode: opcode1, message)
		emit(opcode: opcode2, message)
	}

	func emit(_ byte: Byte, _ message: String) {
		compilingChunk.write(byte, line: parser.previous?.line ?? -1)
	}

	func emit(_ byte1: Byte, _ byte2: Byte, _ message: String) {
		emit(byte1, message)
		emit(byte2, message)
	}

	func emitReturn(_ message: String) {
		emit(opcode: .nil, message)
		emit(opcode: .return, message)
	}

	func error(_ message: String, at token: Token) {
		errors.append(Error(token: token, message: message))
	}

	func error(_ message: String) {
		errors.append(Error(token: nil, message: message))
	}
}
