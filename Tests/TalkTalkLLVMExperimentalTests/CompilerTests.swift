//
//  CompilerTests.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//
import Foundation
import TalkTalkAnalysis
import TalkTalkLLVMExperimental
import Testing

@Suite(.disabled()) struct CompilerTests {
	@Test("Compiles literals") func literals() {
		#expect(Compiler("1").run() == .int(1))
		#expect(Compiler("(2)").run() == .int(2))
	}

	@Test("Compiles add") func add() {
		#expect(Compiler("1 + 2").run() == .int(3))
	}

	@Test("Compiles comparison") func comparison() {
		let out = captureOutput {
			_ = Compiler("if 1 < 2 { printf(1) } else { printf(2) }").run()
			_ = Compiler("if 1 > 2 { printf(1) } else { printf(2) }").run()
		}.output

		#expect(out == "1\n2\n")
	}

	@Test("Compiles def") func def() {
		#expect(Compiler("""
		abc = 1 + 2
		abc
		""").run() == .int(3))
	}

	@Test("Compiles multiple") func multiple() {
		#expect(Compiler("""
		a = 1
		b = 2
		a + b
		""").run() == .int(3))
	}

	@Test("Compiles if") func ifEval() {
		#expect(Compiler("""
		if false {
			a = 1
		} else {
			a = 2
		}
		a
		""").run() == .int(2))
	}

	@Test("Evaluates while") func whileEval() {
		#expect(Compiler("""
		a = 0
		while a != 4 {
			a = a + 1
		}
		a
		""").run() == .int(4))
	}

	@Test("Compiles functions") func functions() {
		#expect(Compiler("""
		func(x) {
			x + 2
		}(2)
		""", verbose: true).run() == .int(4))
	}

	@Test("Compiles closures") func closures() {
		#expect(Compiler("""
		i = 1
		func(x) {
			i + x
		}(2)
		""", verbose: true).run() == .int(3))
	}

	@Test("Compiles counter") func counter() {
		#expect(Compiler("""
		makeCounter = func makeCounter() {
			count = 0
			func counter() {
				count = count + 1
				count
			}
		}

		thecounter = makeCounter()
		thecounter()
		thecounter()
		""", verbose: true).run() == .int(2))
	}

	@Test("Compiles nested scopes") func nestedScopes() {
		#expect(Compiler("""
		addthis = func addthis(x) {
			func inner(y) {
				x + y
			}
		}

		addfour = addthis(4)
		addfour(2)
		""", verbose: true).run() == .int(6))
	}

	@Test("Works with printf") func printTest() {
		let out = captureOutput {
			Compiler("printf(1)").run()
		}

		#expect(out.output == "1\n")
	}

	@Test("Compiles Struct property getter") func structs() {
		#expect(Compiler("""
		struct Foo {
			let age: i32
		}

		foo = Foo(age: 123)
		foo.age + 4
		""").run() == .int(127))
	}

	@Test("Compiles Struct self") func structSelf() {
		#expect(Compiler("""
		struct Foo {
			let age: i32
		
			func getAge() {
				self.age
			}
		}

		foo = Foo(age: 123)
		foo.getAge()
		""", verbose: true).run() == .int(123))
	}

	@Test("Compiles Struct methods") func methods() {
		#expect(Compiler("""
		struct Foo {
			let age: i32

			func add() {
				age + 4
			}
		}

		foo = Foo(123)
		foo.add()
		""", verbose: true).run() == .int(127))
	}

	@Test("Compiles multiple struct methods") func multipleMethods() {
		#expect(Compiler("""
		struct Foo {
			func one() {
				1
			}

			func two() {
				2
			}

			func three() {
				3
			}
		}

		foo = Foo()
		foo.one() + foo.two() + foo.three()
		""", verbose: true).run() == .int(6))
	}

	@Test("Compiles returns") func returns() {
		#expect(Compiler("""
		func returning() {
			return 123
			456
		}

		returning()
		""", verbose: true).run() == .int(123))
	}

	// helpers

	public func captureOutput<R>(block: () -> R) -> (output: String, error: String, result: R) {
		// Create pipes for capturing stdout and stderr
		var stdoutPipe = [Int32](repeating: 0, count: 2)
		var stderrPipe = [Int32](repeating: 0, count: 2)
		pipe(&stdoutPipe)
		pipe(&stderrPipe)

		// Save original stdout and stderr
		let originalStdout = dup(STDOUT_FILENO)
		let originalStderr = dup(STDERR_FILENO)

		// Redirect stdout and stderr to the pipes
		dup2(stdoutPipe[1], STDOUT_FILENO)
		dup2(stderrPipe[1], STDERR_FILENO)
		close(stdoutPipe[1])
		close(stderrPipe[1])

		// Execute the block and capture the result
		let result = block()

		// Restore original stdout and stderr
		dup2(originalStdout, STDOUT_FILENO)
		dup2(originalStderr, STDERR_FILENO)
		close(originalStdout)
		close(originalStderr)

		// Read captured output
		let stdoutData = readData(from: stdoutPipe[0])
		let stderrData = readData(from: stderrPipe[0])

		// Convert data to strings
		let stdoutOutput = String(data: stdoutData, encoding: .utf8) ?? ""
		let stderrOutput = String(data: stderrData, encoding: .utf8) ?? ""

		return (output: stdoutOutput, error: stderrOutput, result: result)
	}

	private func readData(from fd: Int32) -> Data {
		var data = Data()
		let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
		defer { buffer.deallocate() }

		while true {
			let count = read(fd, buffer, 1024)
			if count <= 0 {
				break
			}
			data.append(buffer, count: count)
		}

		return data
	}
}
