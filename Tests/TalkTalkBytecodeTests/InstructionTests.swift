//
//  InstructionTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import Testing
import TalkTalkBytecode

struct InstructionTests {
	@Test("Constant") func constant() {
		_ = Instruction(opcode: .constant, offset: 1, line: 0, metadata: .simple)
	}
}
