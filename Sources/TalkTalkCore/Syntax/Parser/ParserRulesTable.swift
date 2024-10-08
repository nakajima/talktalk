//
//  ParserRulesTable.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//

struct ParserRule {
	typealias PrefixParseFunction = (inout Parser, Bool) -> any Expr
	typealias InfixParseFunction = (inout Parser, Bool, any Expr) -> any Expr

	var prefix: PrefixParseFunction?
	var infix: InfixParseFunction?
	var precedence: Parser.Precedence

	static var none: ParserRule { .init(nil, nil, .none) }

	init(
		_ prefix: PrefixParseFunction? = nil,
		_ infix: InfixParseFunction? = nil,
		_ precedence: Parser.Precedence
	) {
		self.prefix = prefix
		self.infix = infix
		self.precedence = precedence
	}
}

extension Token.Kind {
	var rule: ParserRule {
		switch self {
		case .leftParen: .init({ $0.grouping($1) }, { $0.call($1, $2) }, .call)
		case .rightParen: .none
		case .leftBrace: .init({ $0.blockStmt($1) }, nil, .none)
		case .rightBrace: .none
		// unary
		case .bang: .init({ $0.unary($1) }, nil, .factor)
		// prefix ops
		case .if: .init({ $0.ifExpr($1) }, nil, .none)
		case .identifier: .init({ $0.variable($1) }, nil, .none)
		// Binary ops
		case .equalEqual: .init(nil, { $0.binary($1, $2) }, .equality)
		case .bangEqual: .init(nil, { $0.binary($1, $2) }, .equality)
		case .plus: .init(nil, { $0.binary($1, $2) }, .term)
		case .minus: .init({ $0.unary($1) }, { $0.binary($1, $2) }, .term)
		case .star, .slash: .init(nil, { $0.binary($1, $2) }, .factor)
		case .lessEqual,
		     .greaterEqual: .init(nil, { $0.binary($1, $2) }, .comparison)
		case .less,
		     .greater: .init(nil, { $0.binary($1, $2) }, .comparison)
		case .dot: .init({ $0.dot($1) }, { $0.member($1, $2) }, .call)
		case .is: .init(nil, { $0.binary($1, $2) }, .call)
		case .andAnd: .init(nil, { $0.and($1, $2) }, .and)
		case .pipePipe: .init(nil, { $0.or($1, $2) }, .or)
		// Literals
		case .false: .init({ $0.literal($1) }, nil, .none)
		case .struct: .init({ $0.structExpr($1) }, nil, .none)
		case .func: .init({ $0.literal($1) }, nil, .none)
		case .true: .init({ $0.literal($1) }, nil, .none)
		case .int: .init({ $0.literal($1) }, nil, .none)
		case .float: .init({ $0.literal($1) }, nil, .none)
		case .string: .init({ $0.literal($1) }, nil, .none)
		// []
		case .leftBracket: .init({ $0.arrayLiteral($1) }, .init { $0.subscriptCall($1, $2) }, .call)
		case .rightBracket: .none
		case .return: .none
		case .else: .none
		case .equals: .none
		case .eof: .none
		case .error: .none
		case .newline: .none
		case .symbol: .none
		case .in: .none
		case .call: .none
		case .comma: .none
		case .builtin: .none
		case .while: .none
		case .var: .none
		case .let: .none
		case .colon: .none
		case .self: .none
		case .Self: .none
		case .import: .none
		case .initialize: .none
		case .forwardArrow: .none
		case .semicolon: .none
		case .protocol: .none
		case .enum: .none
		case .match: .none
		case .case: .none
		case .interpolationStart: .none
		case .interpolationEnd: .none
		case .comment: .none
		case .for: .none
		case .questionMark: .none
		case .static: .none
		case .plusEquals: .none
		case .minusEquals: .none
		case .and, .pipe: .none
		}
	}
}
