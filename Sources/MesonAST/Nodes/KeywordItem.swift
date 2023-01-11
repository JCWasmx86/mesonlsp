import SwiftTreeSitter

public class KeywordItem: Expression {
  public let file: MesonSourceFile
  public let key: Node
  public let value: Node
  public var types: [Type] = []

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.key = from_tree(file: file, tree: node.namedChild(at: 0))!
    self.value = from_tree(file: file, tree: node.namedChild(at: 1))!
  }
  public func visit(visitor: CodeVisitor) { visitor.visitKeywordItem(node: self) }
  public func visitChildren(visitor: CodeVisitor) {
    self.key.visit(visitor: visitor)
    self.value.visit(visitor: visitor)
  }
}
