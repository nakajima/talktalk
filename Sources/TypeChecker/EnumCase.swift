//
//  EnumCase.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/6/24.
//

import OrderedCollections

public struct EnumCaseInstance: Equatable, Hashable, CustomStringConvertible {
	let enumCase: EnumCase
	let substitutions: [TypeVariable: InferenceType]

	var attachedTypes: [InferenceType] {
		enumCase.attachedTypes.map {
			if case let .typeVar(typeVar) = $0 {
				substitutions[typeVar] ?? $0
			} else {
				$0
			}
		}
	}

	public var description: String {
		"\(enumCase)\(substitutions)"
	}
}

public struct EnumCase: Equatable, Hashable, CustomStringConvertible {
	public var type: EnumType
	public var name: String
	public var attachedTypes: [InferenceType]
	public var substitutions: [TypeVariable: InferenceType] = [:]

	init(type: EnumType, name: String, attachedTypes: [InferenceType]) {
		self.type = type
		self.name = name
		self.attachedTypes = attachedTypes
	}

	func instantiate(in context: InferenceContext, with substitutions: OrderedDictionary<TypeVariable, InferenceType>) -> EnumCaseInstance {
		EnumCaseInstance(enumCase: self, substitutions: attachedTypes.reduce(into: [:]) { res, type in
			if case let .typeVar(typeVar) = type {
				res[typeVar] = context.applySubstitutions(to: type, with: substitutions)
			}
		})
	}

	public static func extract(from type: InferenceResult) -> EnumCase? {
		if case let .type(.enumCase(enumCase)) = type {
			return enumCase
		}

		return nil
	}

	public var description: String {
		if attachedTypes.isEmpty {
			"\(name)"
		} else {
			"\(name)(\(attachedTypes.map(\.mangled).joined(separator: ", ")))"
		}
	}
}
