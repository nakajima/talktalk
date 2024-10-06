//
//  MemberExprAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/23/24.
//

import TalkTalkBytecode
import TalkTalkCore
import TypeChecker

struct MemberExprAnalyzer: Analyzer {
	let expr: any MemberExpr
	let visitor: SourceFileAnalyzer
	let context: Environment

	func analyze() throws -> any AnalyzedSyntax {
		let type = context.inferenceContext.lookup(syntax: expr)

		// If it's an enum case we want to return a different syntax expression...
		if case let .enumCaseV1(enumCase) = type,
		   let kase = enumCase.type.cases.enumerated().first(where: { $0.element.name == expr.property })
		{
			guard let expr = expr as? MemberExprSyntax else {
				return error(at: expr, "Could not cast \(expr) to MemberExprSyntax", environment: context)
			}

			return AnalyzedEnumMemberExpr(
				wrapped: expr,
				propertyAnalyzed: expr.property,
				paramsAnalyzed: kase.element.attachedTypes,
				inferenceType: .enumCaseV1(kase.element),
				environment: context
			)
		}

		if case let .instantiatable(.enumType(enumType)) = type,
		   let kase = enumType.cases.first(where: { $0.name == expr.property })
		{
			guard let expr = expr as? MemberExprSyntax else {
				return error(at: expr, "Could not cast \(expr) to MemberExprSyntax", environment: context)
			}

			return AnalyzedEnumMemberExpr(
				wrapped: expr,
				propertyAnalyzed: expr.property,
				paramsAnalyzed: kase.attachedTypes,
				inferenceType: .enumCaseV1(kase),
				environment: context
			)
		}

		guard let receiver = try expr.receiver?.accept(visitor, context) else {
			return error(at: expr, "Could not determine receiver", environment: context)
		}

		let propertyName = expr.property
		var memberSymbol: Symbol? = nil
		var analysisDefinition: Definition? = nil

		// If it's boxed, we create members
		if case let .instanceV1(instance) = receiver.typeAnalyzed, instance.type is ProtocolTypeV1 {
			guard let type = instance.member(named: propertyName, in: context.inferenceContext) else {
				return error(at: expr, "No member found for \(instance) named \(propertyName)", environment: context)
			}

			if case let .function(params, _) = type {
				memberSymbol = Symbol(
					module: instance.type.context.moduleName,
					kind: .method(nil, expr.property, params.map(\.mangled))
				)
			} else {
				memberSymbol = Symbol(
					module: instance.type.context.moduleName,
					kind: .property(nil, expr.property)
				)
			}

			if let type = try context.type(named: instance.type.name),
			   let member: any Member = type.methods[expr.property] ?? type.properties[expr.property]
			{
				analysisDefinition = .init(location: member.location, type: member.inferenceType)
			}
		}

		if memberSymbol == nil,
		   case let .instanceV1(instance) = receiver.typeAnalyzed,
		   let member = instance.member(named: expr.property, in: context.inferenceContext)
		{
			if case let .function(params, _) = member {
				memberSymbol = Symbol(
					module: instance.type.context.moduleName,
					kind: .method(instance.type.name, expr.property, params.map(\.mangled))
				)
			} else {
				memberSymbol = Symbol(
					module: instance.type.context.moduleName,
					kind: .property(instance.type.name, expr.property)
				)
			}

			if let type = try context.type(named: instance.type.name),
			   let member: any Member = type.methods[expr.property] ?? type.properties[expr.property]
			{
				analysisDefinition = .init(location: member.location, type: member.inferenceType)
			}
		}

		if memberSymbol == nil,
		   case let .instantiatable(type) = receiver.typeAnalyzed,
		   let member = type.staticMember(named: expr.property, in: context.inferenceContext)
		{
			if case let .function(params, _) = member.asType(in: context.inferenceContext) {
				memberSymbol = Symbol(
					module: type.context.moduleName,
					kind: .method(type.name, expr.property, params.map(\.mangled))
				)
			} else {
				memberSymbol = Symbol(
					module: type.context.moduleName,
					kind: .property(type.name, expr.property)
				)
			}

			if let type = try context.type(named: type.name),
			   let member: any Member = type.methods[expr.property] ?? type.properties[expr.property]
			{
				analysisDefinition = .init(location: member.location, type: member.inferenceType)
			}
		}

		if memberSymbol == nil,
		   case let .enumCaseV1(enumCase) = receiver.typeAnalyzed,
		   let member = enumCase.type.member(named: expr.property, in: context.inferenceContext)
		{
			if case let .function(params, _) = member.asType(in: context.inferenceContext) {
				memberSymbol = Symbol(
					module: enumCase.type.context.moduleName,
					kind: .method(enumCase.type.name, expr.property, params.map(\.mangled))
				)
			} else {
				memberSymbol = Symbol(
					module: enumCase.type.context.moduleName,
					kind: .property(enumCase.type.name, expr.property)
				)
			}

			if let type = try context.type(named: enumCase.type.name),
			   let member: any Member = type.methods[expr.property] ?? type.properties[expr.property]
			{
				analysisDefinition = .init(location: member.location, type: member.inferenceType)
			}
		}

		// If we have an existing lexical scope, use that
		if memberSymbol == nil, let scope = context.getLexicalScope(), let member: (any Member) = scope.methods[propertyName] ?? scope.properties[propertyName] {
			memberSymbol = member.symbol
			analysisDefinition = .init(location: member.location, type: member.inferenceType)
		}

		guard let memberSymbol else {
			return error(at: expr, "Could not find member `\(expr.property)` for type `\(receiver.typeAnalyzed)", environment: context)
		}

		return try AnalyzedMemberExpr(
			inferenceType: type ?? .any,
			wrapped: expr.cast(MemberExprSyntax.self),
			environment: context,
			receiverAnalyzed: castToAnyAnalyzedExpr(receiver, in: context),
			memberSymbol: memberSymbol,
			analysisErrors: [],
			analysisDefinition: analysisDefinition,
			isMutable: false
		)
	}
}
