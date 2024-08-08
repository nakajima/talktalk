//
//  CompilingModule.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkBytecode
import TalkTalkAnalysis

// The compiling module is used during compilation. It can then become a real Module once
// we've sorted out all the intermediary stuff
public class CompilingModule {
	let name: String

	// The completed analysis module. We use this to make sure globals are actually there when
	// asked for in globalOffset
	let analysisModule: AnalysisModule

	// The list of compiled chunks we have.
	var compiledChunks: [Int: Chunk] = [:]

	// Stores globals with their offsets. This is useful for allowing us to calculate an offset
	// for a global before it's been resolved.
	var symbols: [Symbol: Int] = [:]

	// The chunks created for each file being compiled. We can use these to synthesize a main function
	// if none exists.
	var fileChunks: [Chunk] = []

	//
	var valueInitializers: [Symbol: Chunk] = [:]

	// The available modules for import
	let moduleEnvironment: [String: Module]

	public init(name: String, analysisModule: AnalysisModule, moduleEnvironment: [String: Module]) {
		self.name = name
		self.analysisModule = analysisModule
		self.moduleEnvironment = moduleEnvironment

		// Reserve offsets for module functions
		for (i, (_, global)) in analysisModule.functions.enumerated() {
			symbols[.function(global.name)] = i
		}

		// Reserve offsets for module values
		for (i, (_, global)) in analysisModule.values.enumerated() {
			symbols[.value(global.name)] = i + analysisModule.functions.count
		}
	}

	public func finalize() -> Module {
		var chunks: [Chunk] = Array(repeating: Chunk(name: "_"), count: analysisModule.functions.count)

		// Go through the list of global chunks, sort by offset, add to the real module
		for (i, chunk) in compiledChunks.sorted(by: { $0.key < $1.key }) {
			chunks[i] = chunk
		}

		// Copy chunks for imported functions into our module (at some point it'd be nice to just be able to call into those
		// but we'll get there..)
		for (name, global) in analysisModule.functions where global.isImport {
			guard case let .external(analysis) = global.source else {
				fatalError("attempted to import symbol from non-external module")
			}

			guard let module = moduleEnvironment[analysis.name], let moduleOffset = module.symbols[.function(name)] else {
				fatalError("\(analysis.name) not found in module environment")
			}

			guard let offset = moduleFunctionOffset(for: name) else {
				fatalError("no offset registered for imported symbol: \(name)")
			}

			chunks[offset] = module.chunks[moduleOffset]
		}

		let main = if let main = chunks.first(where: { $0.name == "main" }) {
			main
		} else {
			synthesizeMain()
		}

		var module = Module(name: name, main: main, symbols: symbols)

		// Set the module level function chunks
		module.chunks = chunks

		// Set offets for moduleFunction values
		for (i, _) in module.chunks.enumerated() {
			module.functions[Byte(i)] = .moduleFunction(Byte(i))
		}

		// Copy lazy value initializers
		for (name, chunk) in valueInitializers {
			module.valueInitializers[Byte(symbols[name]!)] = chunk
		}

		return module
	}

	public func compile(file: AnalyzedSourceFile) throws {
		var compiler = SourceFileCompiler(name: file.path, analyzedSyntax: file.syntax)
		let chunk = try compiler.compile(in: self)

		// Go through the compiled chunk's subchunks and pull global chunks out to the top level
		let globalNames = Set(analysisModule.functions.values.map(\.name))
		let hoistedChunks = chunk.getSubchunks(named: globalNames)

		for chunk in hoistedChunks {
			guard let offset = symbols[.function(chunk.name)] else {
				fatalError("trying to hoist unknown function")
			}

			compiledChunks[offset] = chunk
		}

		fileChunks.append(chunk)
	}

	// Get an offset for a global by name. If we already have it (it's been compiled) then just
	// return what we have. Otherwise, figure out what the offset will be and return that.
	//
	// If the analysis says that we don't have a global by this name, return nil.
	public func moduleFunctionOffset(for name: String) -> Int? {
		return symbols[.function(name)]
	}

	public func moduleValueOffset(for name: String) -> Int? {
		return symbols[.value(name)]
	}

	func synthesizeMain() -> Chunk {
		let main = Chunk(name: "main")

		for (i, fileChunk) in fileChunks.enumerated() {
			let offset = main.addChunk(fileChunk)
			main.emit(opcode: .callChunkID, line: UInt32(i))
			main.emit(byte: Byte(offset), line: UInt32(i))
		}

		main.emit(opcode: .return, line: UInt32(fileChunks.count))

		return main
	}
}