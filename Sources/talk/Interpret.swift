//
//  Interpret.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

import TalkTalkInterpreter
import ArgumentParser

struct Interpret: TalkTalkCommand {
	static let configuration = CommandConfiguration(
		abstract: "Run the given input in the tree walking interpreter"
	)

	@Argument(help: "The input to interpret.", completion: .file(extensions: [".tlk"]))
	var input: String

	func run() async throws {
		let source = try get(input: input).text
		try print(Interpreter(source).evaluate())
	}
}
