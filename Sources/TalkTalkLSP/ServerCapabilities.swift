//
//  ServerCapabilities.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

struct ServerInfo: Codable {
	enum CodingKeys: CodingKey {
		case name, version
	}

	let name = "talktalk-lsp"
	let version = "0.0.1"
}

struct ServerCapabilities: Codable {
	enum CodingKeys: CodingKey {
		case positionEncoding,
		     serverInfo,
		     textDocumentSync,
		     completionProvider,
		     semanticTokensProvider,
		     documentFormattingProvider,
		     diagnosticProvider,
		     definitionProvider
	}

	let positionEncoding = "utf-8"
	let serverInfo: ServerInfo = .init()
	let textDocumentSync: TextDocumentSyncOptions = .init(change: .full)
	let completionProvider: CompletionOptions = .init()
	let semanticTokensProvider: SemanticTokensOptions = .init()
	let documentFormattingProvider = true
	let diagnosticProvider: DiagnosticOptions = .init()
	let definitionProvider = true
}
