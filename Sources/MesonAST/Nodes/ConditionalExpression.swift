import SwiftTreeSitter

public class ConditionalExpression: Expression {
  public let file: MesonSourceFile
  public let condition: Node
  public let ifTrue: Node
  public let ifFalse: Node
  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.condition = from_tree(file: file, tree: node.namedChild(at: 0))!
    self.ifTrue = from_tree(file: file, tree: node.namedChild(at: 1))!
    self.ifFalse = from_tree(file: file, tree: node.namedChild(at: 1))!
  }
  public func visit(visitor: CodeVisitor) {
    visitor.visitConditionalExpression(node: self)
  }
  public func visitChildren(visitor: CodeVisitor) {
    self.condition.visit(visitor: visitor)
    self.ifTrue.visit(visitor: visitor)
    self.ifFalse.visit(visitor: visitor)
  }
}
