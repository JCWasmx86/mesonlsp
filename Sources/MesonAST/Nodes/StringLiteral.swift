import SwiftTreeSitter

public class StringLiteral: Expression {
  public let file: MesonSourceFile
  public let id: String
  public var types: [Type] = []

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.id = string_value(file: file, node: node)
  }
  public func visit(visitor: CodeVisitor) {
    visitor.visitStringLiteral(node: self)
  }
  public func visitChildren(visitor: CodeVisitor) {
  }
}
