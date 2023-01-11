import SwiftTreeSitter

public class ContinueNode: Statement {
  public let file: MesonSourceFile
  public var types: [Type] = []

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) { self.file = file }
  public func visit(visitor: CodeVisitor) { visitor.visitContinueStatement(node: self) }
  public func visitChildren(visitor: CodeVisitor) {}
}
