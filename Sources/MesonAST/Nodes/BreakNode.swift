import SwiftTreeSitter

public class BreakNode: Statement {
  public let file: MesonSourceFile

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
  }
  public func visit(visitor: CodeVisitor) {
    visitor.visitBreakStatement(node: self)
  }
  public func visitChildren(visitor: CodeVisitor) {
  }
}
