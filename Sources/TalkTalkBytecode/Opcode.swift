//
//  Opcode.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

public enum Opcode: Byte {
	public var byte: Byte { rawValue }

	case `return`,
			 constant,
			 negate,
			 not,

			 // Literals
			 `true`, `false`, none,

			 // Static data
			 data,

			 // Equality
			 equal, notEqual,

			 // Comparisons
			 less, greater, lessEqual, greaterEqual,

			 // Binary operations
			 add, subtract, divide, multiply
}

extension Opcode {
	public var description: String {
		"OP_\(format())"
	}

	func format() -> String {
		return "\(self)"
			.replacing(#/([a-z])([A-Z])/#, with: { "\($0.output.1)_\($0.output.2)" })
			.uppercased()
	}
}
