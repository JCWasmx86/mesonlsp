import SwiftTreeSitter

public final class KeywordItem: Expression {
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
  public func visit(visitor: CodeVisitor) { visitor.visitKeywordItem(node: self) }
  public func visitChildren(visitor: CodeVisitor) {
    self.key.visit(visitor: visitor)
    self.value.visit(visitor: visitor)
  }
  fileprivate init(file: MesonSourceFile, location: Location, key: Node, value: Node) {
    self.file = file
    self.location = location
    self.key = key
    self.value = value
  }
  public func clone() -> Node {
    let location = self.location.clone()
    return Self(file: file, location: location, key: self.key.clone(), value: self.value.clone())
  }
  public func setParents() {
    self.key.parent = self
    self.key.setParents()
    self.value.parent = self
    self.value.setParents()
  }

  public var description: String { return "(KeywordItem \(key): \(value))" }
}
