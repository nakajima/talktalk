//
//  Closure.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/24/24.
//

import TalkTalkSyntax
import TalkTalkAnalysis

public class Closure {
	let funcExpr: AnalyzedFuncExpr
	let environment: Scope

	init(funcExpr: AnalyzedFuncExpr, environment: Scope) {
		self.funcExpr = funcExpr
		self.environment = environment
	}
}
