//
//  Analyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/26/24.
//
import Foundation
import TalkTalkSyntax

// Analyze the AST, trying to figure out types and also checking for errors
public struct SourceFileAnalyzer: Visitor {
	public typealias Context = Environment
	public typealias Value = any AnalyzedSyntax

	var errors: [String] = []

	public init() {}

	public static func analyze(_ exprs: [any Syntax], in environment: Environment) throws
		-> [Value]
	{
		let analyzer = SourceFileAnalyzer()
		let analyzed = try exprs.map {
			try $0.accept(analyzer, environment)
		}

		return analyzed
	}

	public func visit(_ expr: any ExprStmt, _ context: Environment) throws -> any AnalyzedSyntax {
		let exprAnalyzed = try expr.expr.accept(self, context) as! any AnalyzedExpr

		return AnalyzedExprStmt(
			wrapped: expr,
			exprAnalyzed: exprAnalyzed,
			environment: context
		)
	}

	public func visit(_ expr: any ImportStmt, _ context: Environment) -> SourceFileAnalyzer.Value {
		AnalyzedImportStmt(
			environment: context,
			typeID: TypeID(.none),
			stmt: expr
		)
	}

	public func visit(_ expr: any IdentifierExpr, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		AnalyzedIdentifierExpr(
			typeID: TypeID(),
			expr: expr,
			environment: context
		)
	}

	public func visit(_ expr: any UnaryExpr, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		let exprAnalyzed = try expr.expr.accept(self, context)

		switch expr.op {
		case .bang:

			return AnalyzedUnaryExpr(
				typeID: TypeID(.bool),
				exprAnalyzed: exprAnalyzed as! any AnalyzedExpr,
				environment: context,
				wrapped: expr
			)
		case .minus:
			return AnalyzedUnaryExpr(
				typeID: TypeID(.int),
				exprAnalyzed: exprAnalyzed as! any AnalyzedExpr,
				environment: context,
				wrapped: expr
			)
		default:
			fatalError("unreachable")
		}
	}

	public func visit(_ expr: any CallExpr, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		let callee = try expr.callee.accept(self, context)
		var errors: [AnalysisError] = []

		let args = try expr.args.map {
			try AnalyzedArgument(
				label: $0.label,
				expr: $0.value.accept(self, context) as! any AnalyzedExpr
			)
		}

		let type: TypeID
		let arity: Int

		switch callee.typeAnalyzed {
		case let .function(funcName, returning, params, _):
			if params.count == args.count {
				// Try to infer param types, or check types if we already have one
				for (i, param) in params.enumerated() {
					if case .placeholder = param.typeID.type() {
						param.typeID.update(args[i].expr.typeAnalyzed)
					} else if context.shouldReportErrors {
						errors.append(contentsOf: checkAssignment(to: param, value: args[i].expr, in: context))
					}
				}
			}

			var returning = returning
			if returning.type() == .placeholder {
				var funcExpr: AnalyzedFuncExpr? = nil

				if let callee = callee.as(AnalyzedFuncExpr.self) {
					funcExpr = callee
				} else if let callee = callee.as(AnalyzedVarExpr.self),
				          let calleeFunc = context.lookup(callee.name)?.expr.as(AnalyzedFuncExpr.self)
				{
					funcExpr = calleeFunc
				}

				// Don't try this on recursive functions, it doesn't end well. Well actually
				// it just doesn't end.
				if let funcExpr, funcExpr.name?.lexeme != funcName {
					let env = funcExpr.environment.add()
					for param in params {
						env.update(local: param.name, as: param.typeID.current)
					}
					// Try to infer return type now that we know what a param is
					returning = try visit(funcExpr.bodyAnalyzed, env).typeID
				}
			}

			type = returning
			arity = params.count
		case let .struct(t):
			guard let structType = context.lookupStruct(named: t) else {
				return error(
					at: callee, "could not find struct named: \(t)",
					environment: context,
					expectation: .decl
				)
			}

			var instanceType = InstanceValueType.struct(t)

			if let callee = callee as? AnalyzedTypeExpr,
			   let params = callee.genericParams, !params.isEmpty
			{
				// Fill in type parameters if they're explicitly annotated. If they're not we'll have to try to infer them.
				if params.count == structType.typeParameters.count {
					for (i, param) in structType.typeParameters.enumerated() {
						let typeName = params.params[i].name
						let type = context.type(named: typeName)
						instanceType.boundGenericTypes[param.name] = type
					}
				} else if context.shouldReportErrors {
					errors.append(
						context.report(.typeParameterError(
							expected: structType.typeParameters.count,
							received: params.count
						), at: expr.location)
					)
				}
			} else if !structType.typeParameters.isEmpty, let initFn = structType.methods["init"] {
				// Try to infer type parameters from init
				for arg in args {
					// See if we have a label for the arg (could maybe rely on positions here??)
					guard let label = arg.label else { continue }
					// Find the param definition from the init
					guard let param = initFn.params[label] else { continue }

					if case let .instance(paramInstanceType) = param.type(),
					   case let .generic(.struct(structType.name!), typeName) = paramInstanceType.ofType
					{
						instanceType.boundGenericTypes[typeName] = arg.expr.typeAnalyzed
					}
				}
			}

			// TODO: also type check args better?

			type = TypeID(.instance(instanceType))
			arity = structType.methods["init"]!.params.count
		default:
			type = TypeID(.any)
			arity = -1

			// Append the callee not callable error if we don't already have an error
			// on this callee node.
			if callee.analysisErrors.isEmpty {
				errors.append(
					AnalysisError(
						kind: .unknownError("Callee not callable: \(callee.typeAnalyzed)"),
						location: callee.location
					)
				)
			}
		}

		if arity != args.count {
			errors.append(
				context.report(.argumentError(expected: arity, received: args.count), at: expr.location)
			)
		}

		return AnalyzedCallExpr(
			typeID: type,
			expr: expr,
			calleeAnalyzed: callee as! any AnalyzedExpr,
			argsAnalyzed: args,
			analysisErrors: errors,
			environment: context
		)
	}

	public func visit(_ expr: any MemberExpr, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		let receiver = try expr.receiver.accept(self, context)
		let propertyName = expr.property

		var member: (any Member)? = nil
		switch receiver.typeAnalyzed {
		case let .instance(instanceType):
			guard case let .struct(name) = instanceType.ofType,
			      let structType = context.lookupStruct(named: name)
			else {
				return error(
					at: expr, "Could not find type of \(instanceType)", environment: context,
					expectation: .identifier
				)
			}

			member = structType.properties[propertyName] ?? structType.methods[propertyName]
		default:
			return error(
				at: expr, "Cannot access property `\(propertyName)` on `\(receiver)`",
				environment: context,
				expectation: .member
			)
		}

		var errors: [AnalysisError] = []
		if member == nil, context.shouldReportErrors {
			errors.append(
				.init(
					kind: .noMemberFound(receiver: receiver, property: propertyName),
					location: receiver.location
				)
			)
		}

		return AnalyzedMemberExpr(
			typeID: member?.typeID ?? TypeID(.error("no member found")),
			expr: expr,
			environment: context,
			receiverAnalyzed: receiver as! any AnalyzedExpr,
			memberAnalyzed: member ?? error(at: expr, "no member found", environment: context, expectation: .member),
			analysisErrors: errors,
			isMutable: member?.isMutable ?? false
		)
	}

	public func visit(_ expr: any DefExpr, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		let value = try expr.value.accept(self, context) as! any AnalyzedExpr
		let receiver = try expr.receiver.accept(self, context) as! any AnalyzedExpr

		let errors = checkAssignment(to: receiver, value: value, in: context)

		// if errors.isEmpty {
		// switch receiver {
		// 	case let receiver as AnalyzedVarExpr:
		// 		context.define(local: receiver.name, as: value, isMutable: receiver.isMutable)
		// 	default: ()
		// 	}
		// }

		return AnalyzedDefExpr(
			typeID: TypeID(value.typeAnalyzed),
			expr: expr,
			receiverAnalyzed: receiver,
			analysisErrors: errors,
			valueAnalyzed: value,
			environment: context
		)
	}

	public func visit(_ expr: any ParseError, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		AnalyzedErrorSyntax(
			typeID: TypeID(.error(expr.message)),
			expr: expr,
			environment: context
		)
	}

	public func visit(_ expr: any LiteralExpr, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		let typeID = switch expr.value {
		case .int:
			TypeID(.int)
		case .bool:
			TypeID(.bool)
		case .none:
			TypeID(.none)
		case .string:
			TypeID(.instance(.struct("String")))
		}

		if typeID.current == .instance(.struct("String")) {
			_ = context.lookupStruct(named: "String")
		}

		if typeID.current == .instance(.struct("Int")) {
			_ = context.lookupStruct(named: "Int")
		}

		return AnalyzedLiteralExpr(
			typeID: typeID,
			expr: expr,
			environment: context
		)
	}

	public func visit(_ expr: any VarExpr, _ context: Environment) throws -> Value {
		if let binding = context.lookup(expr.name) {
			return AnalyzedVarExpr(
				typeID: binding.type,
				expr: expr,
				environment: context,
				analysisErrors: [],
				isMutable: binding.isMutable
			)
		}

		return AnalyzedVarExpr(
			typeID: TypeID(.any),
			expr: expr,
			environment: context,
			analysisErrors: [
				AnalysisError(kind: .undefinedVariable(expr.name), location: expr.location),
			],
			isMutable: false
		)
	}

	public func visit(_ expr: any BinaryExpr, _ env: Environment) throws -> SourceFileAnalyzer.Value {
		let lhs = try expr.lhs.accept(self, env) as! any AnalyzedExpr
		let rhs = try expr.rhs.accept(self, env) as! any AnalyzedExpr

		if lhs.typeID.current == .pointer,
		   [.int, .placeholder].contains(rhs.typeID.current)
		{
			// This is pointer arithmetic
			// TODO: More generic handling of different operand types
			rhs.typeID.current = .int
		} else {
			infer([lhs, rhs], in: env)
		}

		return AnalyzedBinaryExpr(
			typeID: lhs.typeID,
			expr: expr,
			lhsAnalyzed: lhs,
			rhsAnalyzed: rhs,
			environment: env
		)
	}

	public func visit(_ expr: any IfExpr, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		// TODO: Error if the branches don't match or condition isn't a bool
		try AnalyzedIfExpr(
			typeID: expr.consequence.accept(self, context).typeID,
			expr: expr,
			conditionAnalyzed: expr.condition.accept(self, context) as! any AnalyzedExpr,
			consequenceAnalyzed: visit(expr.consequence, context) as! AnalyzedBlockStmt,
			alternativeAnalyzed: visit(expr.alternative, context) as! AnalyzedBlockStmt,
			environment: context
		)
	}

	public func visit(_ expr: any TypeExpr, _ context: Environment) throws -> any AnalyzedSyntax {
		let type = context.type(named: expr.identifier.lexeme)

		if case let .error(err) = type {
			return error(at: expr, err, environment: context, expectation: .type)
		} else {
			return AnalyzedTypeExpr(
				wrapped: expr,
				typeID: TypeID(type),
				environment: context
			)
		}
	}

	public func visit(_ expr: any FuncExpr, _ env: Environment) throws -> SourceFileAnalyzer.Value {
		let innerEnvironment = env.add()

		// Define our parameters in the environment so they're declared in the body. They're
		// just placeholders for now.
		var params = try visit(expr.params, env) as! AnalyzedParamsExpr
		for param in params.paramsAnalyzed {
			innerEnvironment.define(parameter: param.name, as: param)
		}

		if let name = expr.name {
			// If it's a named function, define a stub inside the function to allow for recursion
			let stubType = ValueType.function(
				name.lexeme,
				TypeID(.placeholder),
				params.paramsAnalyzed.map {
					.init(name: $0.name, typeID: $0.typeID)
				},
				[]
			)
			let stub = AnalyzedFuncExpr(
				type: TypeID(stubType),
				expr: expr,
				analyzedParams: params,
				bodyAnalyzed: .init(
					stmt: expr.body,
					typeID: TypeID(),
					stmtsAnalyzed: [],
					environment: env
				),
				returnsAnalyzed: nil,
				environment: innerEnvironment
			)
			innerEnvironment.define(local: name.lexeme, as: stub, isMutable: false)
		}

		// Visit the body with the innerEnvironment, finding captures as we go.
		let bodyAnalyzed = try visit(expr.body, innerEnvironment) as! AnalyzedBlockStmt

		// See if we can infer any types for our params from the environment after the body
		// has been visited.
		params.infer(from: innerEnvironment)

		let analyzed = ValueType.function(
			expr.name?.lexeme ?? expr.autoname,
			bodyAnalyzed.typeID,
			params.paramsAnalyzed.map { .init(name: $0.name, typeID: $0.typeID) },
			innerEnvironment.captures.map(\.name)
		)

		let funcExpr = AnalyzedFuncExpr(
			type: TypeID(analyzed),
			expr: expr,
			analyzedParams: params,
			bodyAnalyzed: bodyAnalyzed,
			returnsAnalyzed: bodyAnalyzed.stmtsAnalyzed.last,
			environment: innerEnvironment
		)

		if let name = expr.name {
			innerEnvironment.define(local: name.lexeme, as: funcExpr, isMutable: false)
			env.define(local: name.lexeme, as: funcExpr, isMutable: false)
		}

		return funcExpr
	}

	public func visit(_ expr: any InitDecl, _ context: Environment) throws -> any AnalyzedSyntax {
		let paramsAnalyzed = try expr.parameters.accept(self, context) as! AnalyzedParamsExpr

		let innerEnvironment = context.add()
		for param in paramsAnalyzed.paramsAnalyzed {
			innerEnvironment.define(parameter: param.name, as: param)
		}

		let bodyAnalyzed = try expr.body.accept(self, innerEnvironment)

		guard let lexicalScope = innerEnvironment.getLexicalScope() else {
			return error(at: expr, "Could not determine lexical scope for init", environment: context, expectation: .none)
		}

		return AnalyzedInitDecl(
			wrapped: expr,
			typeID: TypeID(.struct(lexicalScope.scope.name!)),
			environment: innerEnvironment,
			parametersAnalyzed: paramsAnalyzed,
			bodyAnalyzed: bodyAnalyzed as! AnalyzedDeclBlock
		)
	}

	public func visit(_ expr: any ReturnExpr, _ env: Environment) throws -> SourceFileAnalyzer.Value {
		let valueAnalyzed = try expr.value?.accept(self, env)
		return AnalyzedReturnExpr(
			typeID: TypeID(valueAnalyzed?.typeAnalyzed ?? .void),
			environment: env,
			expr: expr,
			valueAnalyzed: valueAnalyzed as? any AnalyzedExpr
		)
	}

	public func visit(_ expr: any ParamsExpr, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		try AnalyzedParamsExpr(
			typeID: TypeID(.void),
			expr: expr,
			paramsAnalyzed: expr.params.enumerated().map { _, param in
				var type = TypeID()

				if let paramType = param.type {
					let analyzedTypeExpr = try visit(paramType, context)
					type = analyzedTypeExpr.typeID
				}

				return AnalyzedParam(
					type: type,
					expr: param,
					environment: context
				)
			},
			environment: context
		)
	}

	public func visit(_ expr: any WhileStmt, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		// TODO: Validate condition is bool
		let condition = try expr.condition.accept(self, context) as! any AnalyzedExpr
		let body = try visit(expr.body, context.withNoAutoReturn()) as! AnalyzedBlockStmt

		return AnalyzedWhileStmt(
			typeID: body.typeID,
			wrapped: expr,
			conditionAnalyzed: condition,
			bodyAnalyzed: body,
			environment: context
		)
	}

	public func visit(_ stmt: any BlockStmt, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		var bodyAnalyzed: [any AnalyzedSyntax] = []

		for bodyExpr in stmt.stmts {
			try bodyAnalyzed.append(bodyExpr.accept(self, context))
		}

		// Add an implicit return for single statement blocks
		if context.canAutoReturn, stmt.stmts.count == 1, let exprStmt = bodyAnalyzed[0] as? AnalyzedExprStmt {
			bodyAnalyzed[0] = AnalyzedReturnExpr(
				typeID: exprStmt.typeID,
				environment: context,
				expr: ReturnExprSyntax(
					returnToken: .synthetic(.return),
					location: [exprStmt.location.start]
				),
				valueAnalyzed: exprStmt.exprAnalyzed
			)
		}

		return AnalyzedBlockStmt(
			stmt: stmt,
			typeID: TypeID(bodyAnalyzed.last?.typeAnalyzed ?? .none),
			stmtsAnalyzed: bodyAnalyzed,
			environment: context
		)
	}

	public func visit(_ expr: any Param, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		AnalyzedParam(
			type: TypeID(),
			expr: expr,
			environment: context
		)
	}

	public func visit(_ expr: any GenericParams, _: Environment) throws -> any AnalyzedSyntax {
		AnalyzedGenericParams(
			wrapped: expr,
			typeID: TypeID(),
			paramsAnalyzed: expr.params.map {
				AnalyzedGenericParam(wrapped: $0)
			}
		)
	}

	public func visit(_ expr: any StructDecl, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		var typeParameters: [TypeParameter] = []
		if let genericParams = expr.genericParams {
			for param in genericParams.params {
				typeParameters.append(.init(name: param.name, type: .placeholder))
			}
		}

		let structType = StructType(
			name: expr.name,
			properties: [:],
			methods: [:],
			typeParameters: typeParameters
		)

		let bodyContext = context.addLexicalScope(
			scope: structType,
			type: .struct(expr.name),
			expr: expr
		)

		bodyContext.define(
			local: "self",
			as: AnalyzedVarExpr(
				typeID: TypeID(
					.instance(.struct(expr.name))
				),
				expr: VarExprSyntax(
					token: .synthetic(.self),
					location: [.synthetic(.self)]
				),
				environment: context,
				analysisErrors: [],
				isMutable: false
			),

			isMutable: false
		)

		context.define(struct: expr.name, as: structType)
		bodyContext.define(struct: expr.name, as: structType)

		// Do a first pass over the body decls so we have a basic idea of what's available in
		// this struct.
		for decl in expr.body.decls {
			switch decl {
			case let decl as VarDecl:
				var type = bodyContext.type(named: decl.typeDecl)

				if case .struct = type {
					type = .instance(
						InstanceValueType(
							ofType: type,
							boundGenericTypes: [:]
						)
					)
				}

				if case .generic = type {
					type = .instance(
						InstanceValueType(
							ofType: type,
							boundGenericTypes: [:]
						)
					)
				}

				let property = Property(
					slot: structType.properties.count,
					name: decl.name,
					typeID: TypeID(type),
					expr: decl,
					isMutable: true
				)
				structType.add(property: property)
			case let decl as LetDecl:
				var type = bodyContext.type(named: decl.typeDecl)

				if case .struct = type {
					type = .instance(
						InstanceValueType(
							ofType: type,
							boundGenericTypes: [:]
						)
					)
				}

				if case .generic = type {
					type = .instance(
						InstanceValueType(
							ofType: type,
							boundGenericTypes: [:]
						)
					)
				}

				structType.add(
					property: Property(
						slot: structType.properties.count,
						name: decl.name,
						typeID: TypeID(type),
						expr: decl,
						isMutable: false
					))
			case let decl as FuncExpr:
				if let name = decl.name {
					structType.add(
						method: Method(
							slot: structType.methods.count,
							name: name.lexeme,
							params: decl
								.params
								.params
								.map(\.name)
								.reduce(into: [:]) { res, p in
									res[p] = TypeID(.placeholder)
								},
							typeID: TypeID(
								.function(
									name.lexeme,
									TypeID(.placeholder),
									[],
									[]
								)
							),
							expr: decl,
							isMutable: false
						))
				} else {
					FileHandle.standardError.write(Data(("unknown decl in struct: \(decl.debugDescription)" + "\n").utf8))
				}
			case let decl as InitDecl:
				structType.add(
					initializer: .init(
						slot: structType.methods.count,
						name: "init",
						params: decl
							.parameters
							.params
							.map(\.name)
							.reduce(into: [:]) { res, p
								in res[p] = TypeID(.placeholder)
							},
						typeID: TypeID(
							.function(
								"init",
								TypeID(.placeholder),
								[],
								[]
							)
						),
						expr: decl,
						isMutable: false
					))
			case is ParseError:
				()
			default:
				FileHandle.standardError.write(Data(("unknown decl in struct: \(decl.debugDescription)" + "\n").utf8))
			}
		}

		// Do a second pass to try to fill in method returns
		let bodyAnalyzed = try visit(expr.body, bodyContext)

		let type: ValueType = .struct(
			structType.name ?? expr.description
		)

		// See if there's an initializer defined. If not, generate one.
		if structType.methods["init"] == nil {
			structType.add(
				initializer: .init(
					slot: structType.methods.count,
					name: "init",
					params: structType.properties.reduce(into: [:]) { res, prop in res[prop.key] = prop.value.typeID },
					typeID: TypeID(
						.function(
							"init",
							TypeID(.placeholder),
							[],
							[]
						)
					),
					expr: expr,
					isMutable: false,
					isSynthetic: true
				))
		}

		let lexicalScope = bodyContext.getLexicalScope()!

		let analyzed = AnalyzedStructDecl(
			wrapped: expr,
			bodyAnalyzed: bodyAnalyzed as! AnalyzedDeclBlock,
			structType: structType,
			lexicalScope: lexicalScope,
			typeID: TypeID(type),
			environment: context
		)

		context.define(local: expr.name, as: analyzed, isMutable: false)

		bodyContext.lexicalScope = lexicalScope

		return analyzed
	}

	public func visit(_ expr: any DeclBlock, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		var declsAnalyzed: [any AnalyzedExpr] = []

		// Do a first pass over the body decls so we have a basic idea of what's available in
		// this struct.
		for decl in expr.decls {
			guard let declAnalyzed = try decl.accept(self, context) as? any AnalyzedDecl else {
				continue
			}

			declsAnalyzed.append(declAnalyzed)

			// If we have an updated type for a method, update the struct to know about it.
			if let funcExpr = declAnalyzed as? AnalyzedFuncExpr,
			   let lexicalScope = context.lexicalScope,
			   let name = funcExpr.name?.lexeme,
			   let existing = lexicalScope.scope.methods[name]
			{
				lexicalScope.scope.add(
					method: Method(
						slot: existing.slot,
						name: funcExpr.name!.lexeme,
						params: funcExpr.params.params.map(\.name).reduce(into: [:]) { res, p in res[p] = TypeID(.placeholder) },
						typeID: funcExpr.typeID,
						expr: funcExpr,
						isMutable: false
					))
			}
		}

		return AnalyzedDeclBlock(
			typeID: TypeID(.void),
			decl: expr,
			declsAnalyzed: declsAnalyzed as! [any AnalyzedDecl],
			environment: context
		)
	}

	public func visit(_ expr: any VarDecl, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		var errors: [AnalysisError] = []

		if let existing = context.local(named: expr.name),
			 let definition = existing.definition,
			 definition.location.start != expr.location.start,
			 context.shouldReportErrors {
			errors.append(
				.init(
					kind: .invalidRedeclaration(variable: expr.name, existing: existing),
					location: expr.location
				)
			)
		}

		let type = context.type(named: expr.typeDecl)

		if case .error = type, context.shouldReportErrors {
			errors.append(
				.init(
					kind: .typeNotFound(expr.typeDecl ?? "<no type name>"),
					location: [expr.typeDeclToken ?? expr.location.start]
				)
			)
		}

		let value = try expr.value?.accept(self, context) as? any AnalyzedExpr
		let decl = AnalyzedVarDecl(
			typeID: TypeID(type),
			expr: expr,
			analysisErrors: errors,
			valueAnalyzed: value,
			environment: context
		)

		if let value {
			context.define(local: expr.name, as: value, definition: decl, isMutable: true)
		}

		return decl
	}

	public func visit(_ expr: any LetDecl, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		var errors: [AnalysisError] = []
		let type = TypeID(context.type(named: expr.typeDecl))

		if let existing = context.local(named: expr.name),
			 let definition = existing.definition,
			 definition.location.start != expr.location.start {
			errors.append(
				.init(
					kind: .invalidRedeclaration(variable: expr.name, existing: existing),
					location: expr.location
				)
			)
		}

		if case .error = type.current {
			errors.append(.init(kind: .typeNotFound(expr.typeDecl ?? "<no type name>"), location: [expr.typeDeclToken ?? expr.location.start]))
		}

		var valueType = type
		let value = try expr.value?.accept(self, context) as? any AnalyzedExpr
		if let value, valueType.current == .placeholder {
			valueType = value.typeID
		}

		let decl = AnalyzedLetDecl(
			typeID: valueType,
			expr: expr,
			analysisErrors: errors,
			valueAnalyzed: value,
			environment: context
		)

		if let value {
			context.define(local: expr.name, as: value, definition: decl, isMutable: false)
		}

		return decl
	}

	public func visit(_ expr: any IfStmt, _ context: Environment) throws -> any AnalyzedSyntax {
		try AnalyzedIfStmt(
			wrapped: expr,
			typeID: TypeID(.void),
			conditionAnalyzed: expr.condition.accept(self, context) as! AnalyzedExpr,
			consequenceAnalyzed: expr.consequence.accept(self, context.withNoAutoReturn()) as! AnalyzedExpr,
			alternativeAnalyzed: expr.alternative?.accept(self, context.withNoAutoReturn()) as? AnalyzedExpr
		)
	}

	public func visit(_: any StructExpr, _: Environment) throws -> any AnalyzedSyntax {
		fatalError("TODO")
	}

	// GENERATOR_INSERTION

	private func infer(_ exprs: [any AnalyzedExpr], in env: Environment) {
		let type = exprs.map(\.typeID.current).max(by: { $0.specificity < $1.specificity }) ?? .placeholder

		for var expr in exprs {
			if let exprStmt = expr as? AnalyzedExprStmt {
				// Unwrap expr stmt
				expr = exprStmt.exprAnalyzed
			}

			if let expr = expr as? AnalyzedVarExpr {
				expr.typeID.update(type)
				env.update(local: expr.name, as: type)
				if let capture = env.captures.first(where: { $0.name == expr.name }) {
					capture.binding.type.update(type)
				}
			}
		}
	}

	public func checkAssignment(
		to receiver: any Typed,
		value: any AnalyzedExpr,
		in env: Environment
	) -> [AnalysisError] {
		var errors: [AnalysisError] = []

		if !env.shouldReportErrors {
			return errors
		}

		errors.append(contentsOf: checkMutability(of: receiver, in: env))

		if value.typeID.current == .placeholder {
			value.typeID.current = receiver.typeID.current
		}

		if receiver.typeID.current.isAssignable(from: value.typeAnalyzed) {
			receiver.typeID.current = value.typeID.current
			return errors
		}

		errors.append(
			AnalysisError(
				kind: .typeCannotAssign(
					expected: receiver.typeID,
					received: value.typeID
				),
				location: value.location
			)
		)

		return errors
	}

	func checkMutability(of receiver: any Typed, in env: Environment) -> [AnalysisError] {
		switch receiver {
		case let receiver as AnalyzedVarExpr:
			let binding = env.lookup(receiver.name)

			if !receiver.isMutable || (binding?.isMutable == false) {
				return [
					AnalysisError(
						kind: .cannotReassignLet(variable: receiver),
						location: receiver.location
					),
				]
			}
		case let receiver as AnalyzedMemberExpr:
			if !receiver.isMutable {
				return [AnalysisError(
					kind: .cannotReassignLet(variable: receiver),
					location: receiver.location
				)]
			}
		default:
			()
		}

		return []
	}

	public func error(
		at expr: any Syntax, _ message: String, environment: Environment, expectation: ParseExpectation
	) -> AnalyzedErrorSyntax {
		AnalyzedErrorSyntax(
			typeID: TypeID(.error(message)),
			expr: ParseErrorSyntax(location: expr.location, message: message, expectation: expectation),
			environment: environment
		)
	}
}
