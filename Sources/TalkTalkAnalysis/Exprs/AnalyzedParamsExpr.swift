//
//  AnalyzedParamsExpr.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

import TalkTalkSyntax

public class AnalyzedParam: Param, AnalyzedExpr {
	public func accept<V>(_: V, _: V.Context) -> V.Value where V: AnalyzedVisitor {
		fatalError("unreachable")
	}

	public func accept<V>(_ visitor: V, _ context: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, context)
	}

	public var name: String { expr.name }
	let expr: any Param
	public var analyzedChildren: [any AnalyzedExpr] { [] }
	public let environment: Analyzer.Environment

	public var type: ValueType
	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }

	public init(type: ValueType, expr: any Param, environment: Analyzer.Environment) {
		self.expr = expr
		self.type = type
		self.environment = environment
	}
}

public extension Param where Self == AnalyzedParam {
	static func int(_ name: String) -> AnalyzedParam {
		AnalyzedParam(type: .int, expr: ParamSyntax(name: name, location: [.synthetic(.identifier, lexeme: name)]), environment: .init())
	}
}

public struct AnalyzedParamsExpr: AnalyzedExpr, ParamsExpr {
	public var type: ValueType
	let expr: ParamsExpr

	public var analyzedChildren: [any AnalyzedExpr] { paramsAnalyzed }
	public var paramsAnalyzed: [AnalyzedParam]
	public var environment: Analyzer.Environment

	public var params: [any Param] { expr.params }
	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }

	public var isVarArg = false

	public mutating func infer(from env: Analyzer.Environment) {
		for (i, name) in paramsAnalyzed.enumerated() {
			if let binding = env.infer(name.name) {
				paramsAnalyzed[i].type = binding.type
			}
		}
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}

extension AnalyzedParamsExpr: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: AnalyzedParam...) {
		self.expr = ParamsExprSyntax(
			params: elements.map {
				ParamSyntax(name: $0.name, location: [.synthetic(.identifier, lexeme: $0.name)])
			},
			location: [.synthetic(.identifier)]
		)
		self.paramsAnalyzed = elements
		self.type = .void
		self.environment = if let element = elements.first {
			element.environment
		} else {
			.init()
		}
	}

	public typealias ArrayLiteralElement = AnalyzedParam
}
