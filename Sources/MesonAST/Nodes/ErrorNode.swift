import SwiftTreeSitter

public class ErrorNode: Node {
  public let file: MesonSourceFile
  public let message: String

  init(file: MesonSourceFile, msg: String) {
    self.file = file
    self.message = msg
  }
  init(file: MesonSourceFile, node: SwiftTreeSitter.Node, msg: String) {
    self.file = file
    self.message = msg
  }
  public func visit(visitor: CodeVisitor) {
    visitor.visitErrorNode(node: self)
  }
  public func visitChildren(visitor: CodeVisitor) {
  }
}
