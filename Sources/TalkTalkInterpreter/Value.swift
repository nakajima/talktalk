//
//  Value.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkAnalysis

public struct StructType {
	var name: String?
	var properties: [String: InferenceType]
	var methods: [String: AnalyzedFuncExpr]
}

public struct StructInstance {
	var type: StructType
	var properties: [String: Value]

	public func resolve(property: String) -> Value? {
		if let value = properties[property] {
			return value
		}

		if let funcExpr = type.methods[property] {
			return .method(funcExpr, self)
		}

		return nil
	}
}

public indirect enum Value: Equatable, Comparable {
	case int(Int),
	     bool(Bool),
	     string(String),
	     none,
	     error(String),
	     fn(Closure),
	     method(AnalyzedFuncExpr, StructInstance),
	     type(String),
	     `struct`(StructType),
	     instance(StructInstance),
	     `return`(Value),
	     builtin(String)

	public static func < (lhs: Value, rhs: Value) -> Bool {
		switch lhs {
		case let .int(int):
			guard case let .int(rhs) = rhs else {
				return false
			}

			return int < rhs
		default:
			return false
		}
	}

	public static func == (lhs: Value, rhs: Value) -> Bool {
		switch (lhs, rhs) {
		case let (.string(lhs), .string(rhs)):
			lhs == rhs
		case let (.int(lhs), .int(rhs)):
			lhs == rhs
		case let (.bool(lhs), .bool(rhs)):
			lhs == rhs
		case let (.fn(lhs), .fn(rhs)):
			lhs.funcExpr.id == rhs.funcExpr.id
		default:
			false
		}
	}

	public var type: Value {
		switch self {
		case .int:
			.type("int")
		case .bool:
			.type("bool")
		case .string:
			.type("String")
		case .none:
			.type("none")
		case .error:
			.type("error")
		case .fn:
			.type("func")
		case .method:
			.type("method")
		case let .type(string):
			.type(string)
		case .struct:
			.type("Struct")
		case let .instance(structInstance):
			.type(structInstance.type.name ?? "<no name>")
		case .return:
			.type("Return")
		case let .builtin(string):
			.type(string)
		}
	}

	public func negate() -> Value {
		switch self {
		case let .int(int):
			.int(-int)
		case let .bool(bool):
			.bool(!bool)
		default:
			.error("Cannot negate \(self)")
		}
	}

	public var isTruthy: Bool {
		switch self {
		case .type:
			true
		case .int:
			true
		case .string:
			true
		case .method:
			true
		case .struct(_), .instance:
			true
		case .builtin:
			true
		case let .bool(bool):
			bool
		case .none:
			false
		case .error:
			false
		case .fn:
			false
		case .return:
			false
		}
	}

	public func add(_ other: Value) -> Value {
		switch self {
		case let .int(int):
			guard case let .int(other) = other else {
				return .error("Cannot add \(other) to \(self)")
			}

			return .int(int + other)
		default:
			return .error("Cannot add \(other) to \(self)")
		}
	}

	public func minus(_ other: Value) -> Value {
		switch self {
		case let .int(int):
			guard case let .int(other) = other else {
				return .error("Cannot subtract \(other) from \(self)")
			}

			return .int(int - other)
		default:
			return .error("Cannot subtract \(other) from \(self)")
		}
	}

	public func times(_ other: Value) -> Value {
		switch self {
		case let .int(int):
			guard case let .int(other) = other else {
				return .error("Cannot multiply \(other) by \(self)")
			}

			return .int(int * other)
		default:
			return .error("Cannot multiply \(other) by \(self)")
		}
	}

	public func div(_ other: Value) -> Value {
		switch self {
		case let .int(int):
			if int == 0 {
				return .error("Cannot divide \(other) by zero")
			}

			guard case let .int(other) = other else {
				return .error("Cannot divide \(other) by \(self)")
			}

			return .int(int / other)
		default:
			return .error("Cannot divide \(other) by \(self)")
		}
	}
}
