//
//  StringParser.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/12/24.
//

struct StringParser<S: StringProtocol> {
	enum Context {
		case normal, beforeInterpolation, afterInterpolation
	}

	enum StringError: Error {
		case invalidEscapeSequence(Character)

		var errorDescription: String {
			switch self {
			case let .invalidEscapeSequence(character):
				"Invalid escape sequence: \\\(character)"
			}
		}
	}

	let input: S
	var current: String.Index
	let context: Context
	var endOffset: Int = 0

	static func parse(_ string: S, context: Context) throws -> String {
		var parser = StringParser(input: string, context: context)
		return try parser.parsed()
	}

	init(input: S, context: Context) {
		self.input = input
		self.current = input.startIndex
		self.context = context

		switch context {
		case .normal:
			// Skip the opening '"'
			advance()
			// Skip the ending '"'
			self.endOffset = -1
		case .beforeInterpolation:
			// Skip the opening '"'
			advance()
			// but don't look for '"' at the end
			self.endOffset = 0
		case .afterInterpolation:
			// Don't bother skipping opening '"'
			self.endOffset = -1
		}
	}

	mutating func next() -> Character? {
		if current == input.endIndex {
			return nil
		}

		if current == input.index(input.endIndex, offsetBy: endOffset) {
			return nil
		}

		defer {
			advance()
		}

		return input[current]
	}

	mutating func advance() {
		if current < input.endIndex {
			current = input.index(after: current)
		}
	}

	mutating func parsed() throws -> String {
		var result = ""

		while let char = next() {
			guard char == "\\" else {
				// If we're not escaping we can just append the character and move on
				result.append(char)
				continue
			}

			// If it was "\" then skip that and see what's next
			guard let char = next() else {
				break
			}

			switch char {
			case "n": result.append("\n")
			case "t": result.append("\t")
			case #"""#: result.append(#"""#)
			case #"\"#: result.append(#"\"#)
			default:
				throw StringError.invalidEscapeSequence(char)
			}
		}

		return result
	}

	public static func escape(_ string: S) -> String {
		var escapedString = ""

		for char in string {
			switch char {
			case "\n":
				escapedString += "\\n"
			case "\t":
				escapedString += "\\t"
			case "\"":
				escapedString += "\\\""
			case "\\":
				escapedString += "\\\\"
			default:
				escapedString.append(char)
			}
		}

		return escapedString
	}
}
