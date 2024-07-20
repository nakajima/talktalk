//
//  Value.swift
//  
//
//  Created by Pat Nakajima on 7/20/24.
//

import TalkTalkSyntax

public struct Literal: SemanticNode {
	public var syntax: any Syntax
	public var scope: Scope
	public var type: any SemanticType
}
