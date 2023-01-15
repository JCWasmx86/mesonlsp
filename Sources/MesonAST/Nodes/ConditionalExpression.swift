import SwiftTreeSitter

public class ConditionalExpression: Expression {
  public let file: MesonSourceFile
  public var condition: Node
  public var ifTrue: Node
  public var ifFalse: Node
  public var types: [Type] = []
  public let location: Location
  public weak var parent: Node?

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.location = Location(node: node)
    self.condition = from_tree(file: file, tree: node.namedChild(at: 0))!
    self.ifTrue = from_tree(file: file, tree: node.namedChild(at: 1))!
    self.ifFalse = from_tree(file: file, tree: node.namedChild(at: 1))!
  }
  public func visit(visitor: CodeVisitor) { visitor.visitConditionalExpression(node: self) }
  public func visitChildren(visitor: CodeVisitor) {
    self.condition.visit(visitor: visitor)
    self.ifTrue.visit(visitor: visitor)
    self.ifFalse.visit(visitor: visitor)
  }
  public func setParents() {
    self.condition.parent = self
    self.condition.setParents()
    self.ifTrue.parent = self
    self.ifTrue.setParents()
    self.ifFalse.parent = self
    self.ifFalse.setParents()
  }
  public var description: String {
    return "(ConditionalExpression \(condition) ? \(ifTrue) : \(ifFalse))"
  }
}
