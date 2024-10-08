//
//  BuiltinFunction.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

import TalkTalkCore

public struct BuiltinFunction {
	public let name: String
	public let type: InferenceType

	public static var list: [BuiltinFunction] {
		[
			.print,
			._allocate,
			._free,
			._deref,
			._storePtr,
			._hash,
			._cast,
		]
	}

	static func syntheticExpr() -> any Expr {
		IdentifierExprSyntax(id: -4, name: "__builtin__", location: [.synthetic(.builtin)])
	}

	public static var print: BuiltinFunction {
		BuiltinFunction(
			name: "print",
			type: .function(
				[
					.type(.any),
				],
				.type(.void)
			)
		)
	}

	public static var _allocate: BuiltinFunction {
		BuiltinFunction(
			name: "_allocate",
			type: .function(
				[.type(.base(.int))],
				.type(.base(.pointer))
			)
		)
	}

	public static var _free: BuiltinFunction {
		BuiltinFunction(
			name: "_free",
			type: .function(
				[.type(.base(.pointer))],
				.type(.void)
			)
		)
	}

	public static var _deref: BuiltinFunction {
		let returns = TypeVariable.new("_deref")

		return BuiltinFunction(
			name: "_deref",
			type: .function(
				[.type(.base(.pointer))],
				.type(.typeVar(returns))
			)
		)
	}

	public static var _storePtr: BuiltinFunction {
		BuiltinFunction(
			name: "_storePtr",
			type: .function(
				[
					.type(.base(.pointer)),
					.type(.any),
				],
				.type(.void)
			)
		)
	}

	public static var _hash: BuiltinFunction {
		BuiltinFunction(
			name: "_hash",
			type: .function(
				[.type(.any)],
				.type(.base(.int))
			)
		)
	}

	public static var _cast: BuiltinFunction {
		let typeVar = TypeVariable.new("_cast")

		return BuiltinFunction(
			name: "_cast",
			type: .function(
				[
					.type(.any),
					.type(.kind(.typeVar(typeVar))),
				],
				.type(.typeVar(typeVar))
			)
		)
	}

	public var parameters: [String] {
		guard case let .function(array, _) = type else {
			return []
		}

		return array.map(\.description)
	}
}
