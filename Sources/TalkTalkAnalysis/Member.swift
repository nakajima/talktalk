//
//  Member.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/9/24.
//

import TalkTalkBytecode
import TalkTalkCore

public protocol Member {
	var name: String { get }
	var symbol: Symbol { get }
	var inferenceType: InferenceType { get }
	var location: SourceLocation { get }
	var isMutable: Bool { get }
	var isStatic: Bool { get }
}
