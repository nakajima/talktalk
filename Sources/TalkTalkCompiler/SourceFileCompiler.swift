//
//  Compiler.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import TalkTalkBytecode
import TalkTalkAnalysis

public struct SourceFileCompiler {
	public var number = 0
	public var name: String
	public var chunk: Chunk
	public let analyzedSyntax: [any AnalyzedSyntax]

	public init(name: String, analyzedSyntax: [any AnalyzedSyntax]) {
		self.name = name
		self.analyzedSyntax = analyzedSyntax
		self.chunk = Chunk(name: name)
	}

	public mutating func compile(in module: CompilingModule) throws -> Chunk {
		let visitor = ChunkCompiler(module: module)

		for expr in analyzedSyntax {
			try expr.accept(visitor, chunk)
		}

		// Always emit a `return` since we start with a frame
		return chunk.finalize()
	}
}