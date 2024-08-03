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
		_ = Instruction(opcode: .constant, line: 0, offset: 1, metadata: .simple)
	}
}
