//
//  TextDocumentCompletionRequest.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

struct TextDocumentCompletionRequest: Decodable {
	enum TriggerKind: Int, Decodable {
		case invoked = 1, character = 2, forIncompleteCompletions = 3
	}

	struct Context: Decodable {
		let triggerKind: TriggerKind
	}

	let position: Position
	let textDocument: TextDocument
	let context: Context
}


