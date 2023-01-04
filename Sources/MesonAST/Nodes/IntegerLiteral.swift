import SwiftTreeSitter

public class IntegerLiteral: Expression {
  public let file: MesonSourceFile
  public let value: String

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.value = string_value(file: file, node: node)
  }
  public func visit(visitor: CodeVisitor) {
    visitor.visitIntegerLiteral(node: self)
  }
  public func visitChildren(visitor: CodeVisitor) {
  }
}
