//
//  Member.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/9/24.
//

import TalkTalkSyntax

public protocol Member {
	var slot: Int { get }
	var name: String { get }
	var type: ValueType { get }
	var expr: any Syntax { get }
}