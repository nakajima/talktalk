//
//  ParserRules.swift
//
//
//  Created by Pat Nakajima on 7/1/24.
//
typealias ParseFunction = (inout Compiler, Bool) -> Void

struct ParserRule {
	var prefix: ParseFunction?
	var infix: ParseFunction?
	var precedence: Parser.Precedence

	static var none: ParserRule { .init(nil, nil, .none) }

	init(_ prefix: ParseFunction? = nil, _ infix: ParseFunction? = nil, _ precedence: Parser.Precedence) {
		self.prefix = prefix
		self.infix = infix
		self.precedence = precedence
	}
}

extension Token.Kind {
	var rule: ParserRule {
		return switch self {
		case .leftParen: .init({ $0.grouping($1) }, nil, .none)
		case .rightParen: .none
		case .leftBrace: .none
		case .rightBrace: .none
		case .comma: .none
		case .dot: .none
		case .minus: .init({ $0.unary($1) }, { $0.binary($1) }, .term)
		case .plus: .init(nil, { $0.binary($1) }, .term)
		case .semicolon: .none
		case .slash: .init(nil, { $0.binary($1) }, .factor)
		case .star: .init(nil, { $0.binary($1) }, .factor)
		case .bang: .init({ $0.unary($1) }, nil, .factor)
		case .bangEqual: .init(nil, { $0.binary($1) }, .equality)
		case .equal: .none
		case .equalEqual: .init(nil, { $0.binary($1) }, .equality)
		case .greater: .none
		case .greaterEqual: .none
		case .less: .none
		case .lessEqual: .none
		case .and: .none
		case .andAnd: .none
		case .pipe: .none
		case .pipePipe: .none
		case .identifier: .init({ $0.variable($1) }, nil, .none)
		case .string: .init({ $0.string($1) }, nil, .none)
		case .number: .init({ $0.number($1) }, nil, .none)
		case .class: .none
		case .else: .none
		case .false: .init({ $0.literal($1) }, nil, .none)
		case .func: .none
		case .initializer: .none
		case .for: .none
		case .if: .none
		case .nil: .init({ $0.literal($1) }, nil, .none)
		case .or: .none
		case .print: .none
		case .return: .none
		case .super: .none
		case .self: .none
		case .true: .init({ $0.literal($1) }, nil, .none)
		case .var: .none
		case .while: .none
		case .eof: .none
		case .error: .none
		}
	}
}