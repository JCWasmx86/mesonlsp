import MesonAST
public protocol ExtendedCodeVisitor: CodeVisitor {
	func visitSubdirCall(node: SubdirCall)
}