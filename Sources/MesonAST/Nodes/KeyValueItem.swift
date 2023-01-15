import SwiftTreeSitter

public class KeyValueItem: Expression {
  public let file: MesonSourceFile
  public var key: Node
  public var value: Node
  public var types: [Type] = []
  public let location: Location
  public weak var parent: Node?

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.location = Location(node: node)
    self.key = from_tree(file: file, tree: node.namedChild(at: 0))!
    self.value = from_tree(file: file, tree: node.namedChild(at: 1))!
  }
  public func visit(visitor: CodeVisitor) { visitor.visitKeyValueItem(node: self) }
  public func visitChildren(visitor: CodeVisitor) {
    self.key.visit(visitor: visitor)
    self.value.visit(visitor: visitor)
  }

  public func setParents() {
    self.key.parent = self
    self.key.setParents()
    self.value.parent = self
    self.value.setParents()
  }

  public var description: String { return "(KeyValueItem \(key): \(value))" }
}
