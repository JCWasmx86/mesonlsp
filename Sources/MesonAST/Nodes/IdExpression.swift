import SwiftTreeSitter

public class IdExpression: Expression {
  public let file: MesonSourceFile
  public let id: String

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.id = string_value(file: file, node: node)
  }
  public func visit(visitor: CodeVisitor) {
    visitor.visitIdExpression(node: self)
  }
  public func visitChildren(visitor: CodeVisitor) {
  }
}
