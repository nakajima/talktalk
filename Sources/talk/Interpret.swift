//
//  Interpret.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

import ArgumentParser
import TalkTalkInterpreter

struct Interpret: TalkTalkCommand {
	static let configuration = CommandConfiguration(
		abstract: "Run the given input in the tree walking interpreter (alpha)"
	)

	@Argument(help: "The input to interpret.", completion: .file(extensions: [".talk"]))
	var input: String

	func run() async throws {
		let source = try get(input: input).text
		try print(Interpreter(source).evaluate())
	}
}
