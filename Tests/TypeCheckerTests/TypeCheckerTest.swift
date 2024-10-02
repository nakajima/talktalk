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
	func solve(
		_ syntax: [any Syntax],
		imports: [InferenceContext] = [],
		expectedDiagnostics: Int = 0,
		verbose: Bool = false,
		sourceLocation _: Testing.SourceLocation = #_sourceLocation
	) throws -> Context {
		let context = try ContextVisitor.visit(syntax, verbose: verbose).solve()
		#expect(context.diagnostics.count == expectedDiagnostics, "expected \(expectedDiagnostics) diagnostics. got \(context.diagnostics.count): \(context.diagnostics)")
		return context
	}

	func infer(
		_ expr: [any Syntax],
		imports: [InferenceContext] = [],
		verbose: Bool = false,
		expectedErrors: Int = 0,
		sourceLocation _: Testing.SourceLocation = #_sourceLocation
	) throws -> InferenceContext {
		let inferencer = try Inferencer(moduleName: "TypeCheckerTests", imports: imports, verbose: verbose)
		let context = inferencer.infer(expr).solve().solveDeferred()

		#expect(context.errors.count == expectedErrors, "expected \(expectedErrors) errors. got \(context.errors.count): \(context.errors)")

		return context
	}
}
