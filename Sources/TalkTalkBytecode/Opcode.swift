//
//  Opcode.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

public enum Opcode: Byte, Codable, Sendable, CaseIterable {
	public var byte: Byte { rawValue }

	case returnValue, returnVoid,
	     constant,
	     negate,
	     not,
	     and,

	     noop,

	     // Callables
	     call, callChunkID,

	     // Stack operations
	     pop,

	     // Functions
	     defClosure,

	     // Local variables
	     setLocal,
	     getLocal,

	     // Upvalues (captures)
	     getCapture, setCapture,

	     // Module functions
	     getModuleFunction, setModuleFunction,

	     // Module global values
	     getModuleValue, setModuleValue,

	     // Structs
	     getStruct, setStruct,
	     getProperty, setProperty,
	     getMethod,

	     invokeMethod,

	     // Type casting
	     cast, `is`, primitive,

	     // Builtins
	     getBuiltin, setBuiltin,
	     getBuiltinStruct, setBuiltinStruct,

	     // Dictionaries
	     initDict,

	     // Arrays
	     initArray, get,

	     // Literals
	     `true`,
	     `false`,
	     none,

	     // Static data
	     data,

	     // Suspension
	     suspend,

	     // Equality
	     equal,
	     notEqual,
	     match,

	     // Jumps
	     jump,
	     jumpUnless,
	     jumpPlaceholder,
	     loop,

	     // Pattern matching
	     matchBegin,
	     matchCase,
	     binding,

	     // String interpolation
	     appendInterpolation,

	     // For operations that should have their own scope but allow returning from
	     // their parent, like match statement bodies
	     beginScope,
	     endInline,

	     // Enum stuff
	     getEnum,

	     // Comparisons
	     less,
	     greater,
	     lessEqual,
	     greaterEqual,

	     // Binary operations
	     add,
	     subtract,
	     divide,
	     multiply,

	     // Debuggy
	     debugPrint
}

extension Opcode {
	public var description: String {
		"OP_\(format())"
	}

	func format() -> String {
		"\(self)"
			.replacing(#/([a-z])([A-Z])/#, with: { "\($0.output.1)_\($0.output.2)" })
			.uppercased()
	}
}
