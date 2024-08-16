//
//  TextDocumentFormatting.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

import Foundation
import TalkTalkSyntax

struct TextDocumentFormatting {
	var request: Request

	func readFromDisk(uri: String) async -> SourceDocument? {
		guard let url = URL(string: uri) else {
			return nil
		}

		guard let string = try? String(contentsOf: url, encoding: .utf8) else {
			return nil
		}

		return await SourceDocument(version: nil, uri: uri, text: string)
	}

	func handle(_ server: Server) async {
		let params = request.params as! TextDocumentFormattingRequest

		var source = await server.sources[params.textDocument.uri]
		if source == nil {
			source = await readFromDisk(uri: params.textDocument.uri)
		}

		guard let source else {
			Log.error("could not find source for document uri")
			return
		}

		do {
			let formatted = try await Formatter.format(source.text)
			await server.respond(to: request.id, with: [TextEdit(range: source.range, newText: formatted)])
		} catch {
			Log.error("Error formatting: \(error)")
		}
	}
}
