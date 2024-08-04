//
//  Compile.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//
import ArgumentParser
import Foundation
import TalkTalkLLVMExperimental
import LLVM
import C_LLVM

struct LLVMCompile: TalkTalkCommand {
	@Argument(help: "The input to run.")
	var input: String

	func run() async throws {
		let source = switch try get(input: input) {
		case .path(let string):
			string
		case .stdin:
			fatalError("not yet")
		case .string(let string):
			string
		}

		let module = try Compiler(source).compile(optimize: true)

		module.write(to: "out.bc")

		// Write the module to a file
	}
}