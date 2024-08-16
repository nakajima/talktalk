//
//  TextDocumentDiagnostic.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

import TalkTalkAnalysis

extension AnalysisError {
	func diagnostic() -> Diagnostic {
		let start = location.start
		let end = location.end

		return Diagnostic(
			range: Range(
				start: Position(line: start.line, character: start.column),
				end: Position(line: end.line, character: end.column)
			),
			severity: .error,
			message: message,
			tags: nil,
			relatedInformation: nil
		)
	}

	var message: String {
		switch kind {
		case let .argumentError(expected: a, received: b):
			if a == -1 {
				return "Unable to determine expected arguments, probably because callee isn't callable."
			} else {
				return "Expected \(a) arguments, got: \(b)"
			}
		case let .typeParameterError(expected: a, received: b):
			return "Expected \(a) type parameters, got: \(b)"
		case let .typeNotFound(name):
			return "Unknown type: \(name)"
		case let .unknownError(message):
			return message
		case let .noMemberFound(receiver: receiver, property: property):
			return "No property named `\(property)` for \(receiver)"
		case let .undefinedVariable(name):
			return "Undefined variable `\(name)`"
		case let .typeCannotAssign(expected: expected, received: received):
			return "Cannot assign \(received) to \(expected)"
		case let .cannotReassignLet(variable: syntax):
			return "Cannot re-assign let variable: \(syntax.description)"
		}
	}
}

struct TextDocumentDiagnostic: Decodable {
	var request: Request

	func handle(_ handler: Server) async {
		let params = request.params as! TextDocumentDiagnosticRequest
		
		guard let source = await handler.sources[params.textDocument.uri] else {
			Log.error("no source found for \(params.textDocument.uri)")
			return
		}

		do {
			let environment = Environment() // TODO: Use module environment
			let errorSyntaxes = try await SourceFileAnalyzer.diagnostics(text: source.text, environment: environment)
			let diagnostics = errorSyntaxes.map { $0.diagnostic() }
			let report = FullDocumentDiagnosticReport(items: diagnostics)
			await handler.respond(to: request.id, with: report)
		} catch {
			Log.error("Error generating diagnostics: \(error)")
		}
	}
}
