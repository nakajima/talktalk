//
//  FakeHeapTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/11/24.
//

import Testing

struct FakeHeapTests: StandardLibraryTest {
	@Test("Can allocate") func create() async throws {
		_ = try await run("""
		return _allocate(4)
		""").get()
	}
}
