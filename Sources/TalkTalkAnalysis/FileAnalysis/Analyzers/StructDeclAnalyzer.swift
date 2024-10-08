//
//  StructDeclAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/23/24.
//

import TalkTalkBytecode
import TalkTalkCore
import TypeChecker

struct StructDeclAnalyzer: Analyzer {
	let decl: any StructDecl
	let visitor: SourceFileAnalyzer
	let context: Environment

	func analyze() throws -> any AnalyzedSyntax {
		let inferenceType = context.type(for: decl)
		guard let type = TypeChecker.StructType.extractType(from: .type(inferenceType))
		else {
			return error(at: decl, "did not find struct type from \(decl.name)", environment: context, expectation: .none)
		}

		let structType = AnalysisStructType(
			id: decl.id,
			name: decl.name,
			properties: [:],
			methods: [:],
			typeParameters: decl.typeParameters.map {
				TypeParameter(name: $0.identifier.lexeme, type: $0)
			}
		)

		for decl in decl.body.decls {
			switch decl {
			case let decl as VarLetDecl:
				structType.add(
					property: Property(
						symbol: .property(context.moduleName, structType.name, decl.name),
						name: decl.name,
						inferenceType: context.type(for: decl),
						location: decl.semanticLocation ?? decl.location,
						isMutable: false,
						isStatic: decl.isStatic
					)
				)
			case let decl as FuncExpr:
				let method = context.type(for: decl)
				guard case let .function(params, returns) = method, let name = decl.name?.lexeme else {
					return error(at: decl, "invalid method", environment: context, expectation: .none)
				}

				let symbol = context.symbolGenerator.method(
					structType.name,
					name,
					parameters: params.map(\.mangled),
					source: .internal
				)

				structType.add(
					method: Method(
						name: name,
						symbol: symbol,
						params: params.map { context.inferenceContext.apply($0) },
						inferenceType: method,
						location: decl.semanticLocation ?? decl.location,
						returnTypeID: context.inferenceContext.apply(returns),
						isStatic: decl.isStatic
					)
				)
			case let decl as InitDecl:
				let initializer = context.type(for: decl)
				guard case let .function(params, returns) = initializer else {
					return error(at: decl, "invalid method", environment: context, expectation: .none)
				}

				let symbol = context.symbolGenerator.method(
					structType.name,
					"init",
					parameters: params.map { context.inferenceContext.apply($0).mangled },
					source: .internal
				)

				structType.add(
					initializer: Method(
						name: "init",
						symbol: symbol,
						params: params.map { context.inferenceContext.apply($0) },
						inferenceType: initializer,
						location: decl.semanticLocation ?? decl.location,
						returnTypeID: context.inferenceContext.apply(returns)
					)
				)
			default:
				continue
			}
		}

		//		// If there's no init, synthesize one
		if structType.methods["init"] == nil {
			structType.add(
				initializer: Method(
					name: "init",
					symbol: context.symbolGenerator.method(
						context.moduleName,
						structType.name,
						parameters: structType.properties.values.map(\.inferenceType.mangled),
						source: .internal
					),
					params: structType.properties.values.map(\.inferenceType),
					inferenceType: .function(structType.properties.values.map { .type($0.inferenceType) }, .type(.instantiatable(.struct(type)))),
					location: decl.location,
					returnTypeID: .instance(.synthesized(type)),
					isSynthetic: true
				)
			)
		}

		let bodyContext = context.addLexicalScope(for: structType)

		bodyContext.define(
			local: "self",
			as: AnalyzedVarExpr(
				inferenceType: .instance(.synthesized(type)),
				wrapped: VarExprSyntax(
					id: -8,
					token: .synthetic(.self),
					location: [.synthetic(.self)]
				),
				symbol: bodyContext.symbolGenerator.value("self", source: .internal),
				environment: bodyContext,
				analysisErrors: [],
				isMutable: false
			),
			type: .instance(.synthesized(type)),
			isMutable: false
		)

		for (i, param) in structType.typeParameters.enumerated() {
			// Go through and actually analyze the type params
			let environment = bodyContext.add(namespace: nil)
			environment.isInTypeParameters = true
			structType.typeParameters[i].type = try cast(param.type.accept(visitor, environment), to: AnalyzedTypeExpr.self)
		}

		context.define(type: decl.name, as: structType)

		let symbol = context.symbolGenerator.struct(decl.name, source: .internal)
		let bodyAnalyzed = try visitor.visit(decl.body, bodyContext)

		var errors: [AnalysisError] = []
		for error in context.inferenceContext.errors {
			errors.append(
				.init(
					kind: .inferenceError(error.kind),
					location: error.location
				)
			)
		}

		let analyzed = try AnalyzedStructDecl(
			symbol: symbol,
			wrapped: cast(decl, to: StructDeclSyntax.self),
			bodyAnalyzed: cast(bodyAnalyzed, to: AnalyzedDeclBlock.self),
			structType: structType,
			inferenceType: inferenceType,
			analysisErrors: errors,
			environment: context
		)

		bodyContext.define(type: decl.name, as: structType)

		context.define(local: decl.name, as: analyzed, isMutable: false)

		return analyzed
	}
}
