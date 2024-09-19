//
//  AnalysisTest.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/15/24.
//

import TalkTalkAnalysis
import TalkTalkCore
import TalkTalkSyntax

public protocol AnalysisTest {}

public extension AnalysisTest {
	func analyze(_ string: String) async throws -> AnalysisModule {
		let analyzer = try ModuleAnalyzer(
			name: "AnalysisTest",
			files: [.tmp(string, "Analysis.talk")],
			moduleEnvironment: [:],
			importedModules: []
		)

		return try analyzer.analyze()
	}

	func ast(_ string: String) async throws -> any AnalyzedSyntax {
		let syntax = try await analyze(string).analyzedFiles[0].syntax
		return syntax.last!
	}

	func asts(_ string: String) async throws -> [any AnalyzedSyntax] {
		let syntax = try await analyze(string).analyzedFiles[0].syntax
		return syntax
	}
}
