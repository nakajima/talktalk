//
//  CallFrame.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/4/24.
//

import TalkTalkBytecode
import OrderedCollections

struct Closure {
	var chunk: StaticChunk

	public init(chunk: StaticChunk) {
		self.chunk = chunk
	}
}

public struct CallFrame {
	var ip: UInt64 = 0
	var closure: Closure
	var returnTo: UInt64
	var stackOffset: Int
	var locals: OrderedDictionary<Symbol, Value> = [:]
	var selfValue: Value?
}
