protocol StmtVisitor {
	mutating func visit(_ stmt: PrintStmt) throws
	mutating func visit(_ stmt: ExpressionStmt) throws
	mutating func visit(_ stmt: VarStmt) throws
	mutating func visit(_ stmt: BlockStmt) throws
	mutating func visit(_ stmt: IfStmt) throws
	mutating func visit(_ stmt: WhileStmt) throws
}

protocol Stmt {
	func accept<Visitor: StmtVisitor>(visitor: inout Visitor) throws -> Void
}

struct PrintStmt: Stmt {
	let expr: any Expr

	func accept<Visitor: StmtVisitor>(visitor: inout Visitor) throws {
		try visitor.visit(self)
	}
}

struct ExpressionStmt: Stmt {
	let expr: any Expr

	func accept<Visitor: StmtVisitor>(visitor: inout Visitor) throws {
		try visitor.visit(self)
	}
}

struct VarStmt: Stmt {
	let name: String
	let initializer: (any Expr)?

	func accept<Visitor: StmtVisitor>(visitor: inout Visitor) throws {
		try visitor.visit(self)
	}
}

struct BlockStmt: Stmt {
	let statements: [any Stmt]

	func accept<Visitor: StmtVisitor>(visitor: inout Visitor) throws {
		try visitor.visit(self)
	}
}

struct IfStmt: Stmt {
	let condition: any Expr
	let thenStatement: any Stmt
	let elseStatement: (any Stmt)?

	func accept<Visitor: StmtVisitor>(visitor: inout Visitor) throws {
		try visitor.visit(self)
	}
}

struct WhileStmt: Stmt {
	let condition: any Expr
	let statements: [any Stmt]

	func accept<Visitor: StmtVisitor>(visitor: inout Visitor) throws {
		try visitor.visit(self)
	}
}