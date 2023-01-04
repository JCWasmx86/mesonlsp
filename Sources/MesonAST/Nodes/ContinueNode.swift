import SwiftTreeSitter

public class ContinueNode: Statement {
  public let file: MesonSourceFile

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
  }
  public func visit(visitor: CodeVisitor) {
    visitor.visitContinueStatement(node: self)
  }
  public func visitChildren(visitor: CodeVisitor) {
  }
}
