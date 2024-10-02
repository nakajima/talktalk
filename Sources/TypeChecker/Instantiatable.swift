//
//  Instantiatable.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/2/24.
//

public protocol Instantiatable {
	var name: String { get }

	func instantiate(with substitutions: [TypeVariable: InferenceResult]) -> any Instance
}
