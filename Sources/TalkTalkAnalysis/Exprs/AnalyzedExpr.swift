//
//  AnalyzedExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkCore

public protocol AnalyzedExpr: Expr, AnalyzedSyntax, Typed {
	var analyzedChildren: [any AnalyzedSyntax] { get }
	func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor
}
