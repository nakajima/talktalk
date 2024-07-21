//
//  Block.swift
//
//
//  Created by Pat Nakajima on 7/20/24.
//

import TalkTalkSyntax

public struct Block: SemanticNode {
	public var scope: Scope
	public var syntax: any Syntax
	public var type: any SemanticType
}