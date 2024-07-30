//
//  LetDecl.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

public protocol LetDecl: Decl {
	var name: String { get }
	var typeDecl: String { get }
}

public struct LetDeclSyntax: VarDecl {
	public var name: String
	public var typeDecl: String
	public var location: SourceLocation

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V : Visitor {
		visitor.visit(self, scope)
	}
}
