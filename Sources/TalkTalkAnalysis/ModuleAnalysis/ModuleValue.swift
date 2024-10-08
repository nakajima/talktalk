//
//  ModuleValue.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkBytecode
import TalkTalkCore

public struct ModuleValue: ModuleGlobal {
	public let name: String
	public let symbol: Symbol
	public let location: SourceLocation
	public let typeID: InferenceType
	public var source: ModuleSource
	public var isMutable: Bool

	public var isImport: Bool {
		if case .module = source {
			return false
		}

		return true
	}
}
