//
//  InstanceType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/19/24.
//
import OrderedCollections

public enum InstanceType {
	public func equals(_ rhs: InstanceType) -> Bool {
		switch (self, rhs) {
		case let (.struct(l), .struct(r)):
			l.type == r.type && l.substitutions.keys == r.substitutions.keys
		case let (.enumType(l), .enumType(r)):
			l.type == r.type && l.substitutions.keys == r.substitutions.keys
		case let (.protocol(l), .protocol(r)):
			l.type == r.type && l.substitutions.keys == r.substitutions.keys
		default:
			false
		}
	}

	case `struct`(Instance<StructType>)
	case `protocol`(Instance<ProtocolType>)
	case enumType(Instance<EnumType>)

	public static func synthesized(_ type: some Instantiatable) -> InstanceType {
		// swiftlint:disable force_cast
		switch type {
		case is StructType:
			.struct(.synthesized(type as! StructType))
		case is ProtocolType:
			.protocol(.synthesized(type as! ProtocolType))
		case is EnumType:
			.enumType(.synthesized(type as! EnumType))
		default:
			// swiftlint:disable fatal_error
			fatalError("unable to synthesize instance type: \(type)")
			// swiftlint:enable fatal_error
		}
		// swiftlint:enable force_cast
	}

	func relatedType(named name: String) -> InferenceType? {
		switch self {
		case let .struct(instance):
			instance.relatedType(named: name)
		case let .protocol(instance):
			instance.relatedType(named: name)
		case let .enumType(instance):
			instance.relatedType(named: name)
		}
	}

	var substitutions: OrderedDictionary<TypeVariable, InferenceType> {
		get {
			switch self {
			case let .struct(instance):
				instance.substitutions
			case let .protocol(instance):
				instance.substitutions
			case let .enumType(instance):
				instance.substitutions
			}
		}

		set {
			switch self {
			case let .struct(instance):
				instance.substitutions = newValue
			case let .protocol(instance):
				instance.substitutions = newValue
			case let .enumType(instance):
				instance.substitutions = newValue
			}
		}
	}

	func extract<T: Instantiatable>(_: T.Type) -> Instance<T>? {
		switch self {
		case let .struct(instance):
			instance as? Instance<T>
		case let .protocol(instance):
			instance as? Instance<T>
		case let .enumType(instance):
			instance as? Instance<T>
		}
	}

	public func member(named name: String, in context: InferenceContext) -> InferenceType? {
		switch self {
		case let .struct(instance):
			instance.member(named: name, in: context)
		case let .protocol(instance):
			instance.member(named: name, in: context)
		case let .enumType(instance):
			instance.member(named: name, in: context)
		}
	}

	public var type: any Instantiatable {
		switch self {
		case let .struct(instance):
			instance.type
		case let .protocol(instance):
			instance.type
		case let .enumType(instance):
			instance.type
		}
	}
}

extension InstanceType: CustomStringConvertible {
	public var description: String {
		switch self {
		case let .struct(instance):
			instance.description
		case let .protocol(instance):
			instance.description
		case let .enumType(instance):
			instance.description
		}
	}
}

extension InstanceType: CustomDebugStringConvertible {
	public var debugDescription: String {
		description
	}
}

extension InstanceType: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		switch (lhs, rhs) {
		case let (.enumType(lhs), .enumType(rhs)):
			return lhs == rhs
		case let (.struct(lhs), .struct(rhs)):
			return lhs == rhs
		case let (.protocol(lhs), .protocol(rhs)):
			return lhs == rhs
		default: ()
		}

		return false
	}
}
