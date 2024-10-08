//
//  Request.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

import TalkTalkBytecode

struct MessageParams: Equatable {}

enum RequestID: Equatable, Codable, Sendable, Hashable {
	case integer(Int), string(String)

	init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		if let id = try? container.decode(Int.self) {
			self = .integer(id)
		} else if let id = try? container.decode(String.self) {
			self = .string(id)
		} else {
			throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Could not decode id"))
		}
	}

	func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()

		switch self {
		case let .integer(int):
			try container.encode(int)
		case let .string(string):
			try container.encode(string)
		}
	}
}

struct Request: Equatable, Codable, Sendable {
	static func == (lhs: Request, rhs: Request) -> Bool {
		lhs.id == rhs.id && lhs.method == rhs.method
	}

	enum Params: Equatable {
		case object(MessageParams), array([MessageParams])
	}

	var id: RequestID?
	var method: Method
	var params: (any Decodable & Sendable)?

	enum CodingKeys: CodingKey {
		case id, method, params
	}

	init(id: RequestID?, method: Method, params: (any Decodable & Sendable)? = nil) {
		self.id = id
		self.method = method
		self.params = params
	}

	func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(id, forKey: .id)
		try container.encode(method, forKey: .method)

		if let params = params as? Encodable {
			try container.encode(params, forKey: .params)
		}
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.id = try container.decodeIfPresent(RequestID.self, forKey: .id)
		self.method = try container.decode(Method.self, forKey: .method)
		self.params = switch method {
		case .textDocumentDefinition:
			try container.decode(TextDocumentDefinitionRequest.self, forKey: .params)
		case .textDocumentDidOpen:
			try container.decode(TextDocumentDidOpenRequest.self, forKey: .params)
		case .textDocumentCompletion:
			try container.decode(TextDocumentCompletionRequest.self, forKey: .params)
		case .textDocumentDidChange:
			try container.decode(TextDocumentDidChangeRequest.self, forKey: .params)
		case .textDocumentDiagnostic:
			try container.decode(TextDocumentDiagnosticRequest.self, forKey: .params)
		case .textDocumentFormatting:
			try container.decode(TextDocumentFormattingRequest.self, forKey: .params)
		case .textDocumentSemanticTokensFull:
			try container.decode(TextDocumentSemanticTokensFullRequest.self, forKey: .params)
		case .cancelRequest:
			try container.decode(CancelParams.self, forKey: .params)
		case .initialize,
		     .initialized,
		     .shutdown,
		     .textDocumentDidClose,
		     .workspaceSemanticTokensRefresh,
		     .textDocumentPublishDiagnostics:
			nil
		}
	}
}
