typeName = ARGV[0] # protocol name like "FooExpr"
kind = ARGV[1] # expr/stmt/decl

PROPERTIES = ARGV[2..]

syntaxName = "#{typeName}Syntax"
analyzedName = "Analyzed#{typeName}"

subdir = {
	"expr" => "Exprs",
	"stmt" => "Stmts",
	"decl" => "Decls"
}[kind] || abort("Unknown kind: #{kind}")

conformsTo = {
	"expr" => "Expr",
	"stmt" => "Stmt",
	"decl" => "Decl"
}[kind]

puts "#{typeName}, #{conformsTo}"

def props()
  PROPERTIES.map do |property|
    "\tpublic var " + property
  end.join("\n")
end

def analyzedProps()
  PROPERTIES.map do |property|
    split = property.split(":")
    "\tpublic var " + split[0] + "Analyzed:" + split[1]
	end.join("\n")
end

def write(path, contents)
	if File.exist?(path)
		puts("File already exists: #{path}")
		return
	end

	File.open(path, "w+")	do |file|
		file.puts(contents)
	end
end

def insert(path, contents)
	line = File.read(path).lines.find_index { |line| line.include?("// GENERATOR_INSERTION") }

	if !line
		abort("Could not find insertion point for #{path}")
  end

	lines = File.read(path).lines
	lines.insert(line, contents)
	File.open(path, 'w+') { |file|
		file.puts(lines.join)
	}
end

syntaxPath = "Sources/TalkTalkCore/Syntax/Syntax/#{subdir}/#{typeName}.swift"
syntaxFile = <<~SWIFT
// Generated by Dev/generate-type.rb #{Time.now.strftime("%m/%d/%Y %H:%M")}

public protocol #{typeName}: #{conformsTo} {
	// Insert #{typeName} specific fields here
}

public struct #{typeName}Syntax: #{typeName} {
#{props()}

  // A unique identifier
  public var id: SyntaxID

	// Where does this syntax live
	public var location: SourceLocation

	// Useful for just traversing the whole tree
	public var children: [any Syntax]

	// Let this node be visited by visitors
	public func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(self, context)
	}
}
SWIFT

analyzedPath = "Sources/TalkTalkAnalysis/#{subdir}/Analyzed#{typeName}.swift"
analyzedFile = <<~SWIFT
// Generated by Dev/generate-type.rb #{Time.now.strftime("%m/%d/%Y %H:%M")}

import TalkTalkCore

public struct #{analyzedName}: #{typeName}, Analyzed#{kind.capitalize} {
  public let wrapped: #{typeName}Syntax
#{analyzedProps()}

	public var inferenceType: InferenceType
	public var environment: Environment
	public var analyzedChildren: [any AnalyzedSyntax] { [] }

	// Delegate these to the wrapped node
	public var location: SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(wrapped, context)
	}
}
SWIFT

write(syntaxPath, syntaxFile)
puts "wrote #{syntaxPath}"

write(analyzedPath, analyzedFile)
puts "wrote #{analyzedPath}"

visitorRequirement = <<SWIFT
	func visit(_ expr: #{typeName}Syntax, _ context: Context) throws -> Value
SWIFT

analysisVisitorRequirement = <<SWIFT
	func visit(_ expr: Analyzed#{typeName}, _ context: Context) throws -> Value
SWIFT

insert("Sources/TalkTalkCore/Syntax/Visitor.swift", visitorRequirement)
puts "added visitor requirement to Sources/TalkTalkCore/Syntax/Visitor.swift"

insert("Sources/TalkTalkAnalysis/FileAnalysis/AnalysisVisitor.swift", analysisVisitorRequirement)
puts "added analysis visitor requirement to Sources/TalkTalkAnalysis/FileAnalysis/AnalysisVisitor.swift"

insert "Sources/TalkTalkAnalysis/FileAnalysis/SourceFileAnalyzer.swift", <<SWIFT
	public func visit(_ expr: #{typeName}Syntax, _ context: Environment) throws -> any AnalyzedSyntax {
		#warning("TODO")
    return error(at: expr, "TODO", environment: context, expectation: .none)
	}

SWIFT
puts "added conformance to SourceFileAnalyzer"

insert "Sources/TalkTalkLSP/Handlers/TextDocumentSemanticTokensFull.swift", <<SWIFT
	public func visit(_ expr: #{typeName}Syntax, _ context: Context) throws -> [RawSemanticToken] {
		#warning("TODO")
		return []
	}

SWIFT
puts "added conformance to SemanticTokensFull visitor"

insert "Sources/TalkTalkCompiler/ChunkCompiler.swift", <<SWIFT
	public func visit(_ expr: Analyzed#{typeName}, _ context: Chunk) throws {
		#warning("Generated by Dev/generate-type.rb")
	}
SWIFT
puts "added conformance to ChunkCompiler.swift"

insert "Sources/TypeChecker/Visitors/InferenceVisitor.swift", <<SWIFT
	public func visit(_ expr: #{typeName}Syntax, _ context: Context) throws {
		#warning("Generated by Dev/generate-type.rb")
	}

SWIFT
puts "added conformance to InferenceVisitor.swift"

insert "Sources/TypeChecker/Visitors/PatternVisitor.swift", <<SWIFT
	public func visit(_ expr: #{typeName}Syntax, _ context: Context) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

SWIFT
puts "added conformance to PatternVisitor.swift"

insert "Sources/TalkTalkCore/Syntax/Formatter/FormatterVisitor.swift", <<SWIFT
	public func visit(_ expr: #{typeName}Syntax, _ context: Context) throws -> Doc {
		#warning("Generated by Dev/generate-type.rb")

		return text("TODO")
	}

SWIFT
puts "added conformance to FormatterVisitor.swift"
