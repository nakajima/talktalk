//
//  TypeCheckerTest.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/31/24.
//

import TalkTalkCore
import Testing
@testable import TypeChecker

protocol TypeCheckerTest {}
extension TypeCheckerTest {
	func infer(
		_ expr: [any Syntax],
		imports: [InferenceContext] = [],
		expectedErrors: Int = 0,
		sourceLocation _: Testing.SourceLocation = #_sourceLocation
	) throws -> InferenceContext {
		let inferencer = try Inferencer(moduleName: "TypeCheckerTests", imports: imports)
		let context = inferencer.infer(expr).solve().solveDeferred()

		#expect(context.errors.count == expectedErrors, "expected \(expectedErrors) errors. got \(context.errors.count): \(context.errors)")

		return context
	}
}
