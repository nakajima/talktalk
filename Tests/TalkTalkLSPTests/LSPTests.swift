//
//  LSPTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

import Foundation
@testable import TalkTalkLSP
import Testing

@MainActor
struct LSPTests {
	@Test("String parsing", .disabled()) func inOut() async throws {
		_ = try String(contentsOf: URL.homeDirectory.appending(path: "apps/talktalk/lsp.log"), encoding: .utf8)

//		let message = try JSONDecoder().decode(RPC.Request.self, from: Data(input.split(separator: "\r\n\r\n").last!.utf8))
//		#expect(message.id == .integer(1))
	}
}
