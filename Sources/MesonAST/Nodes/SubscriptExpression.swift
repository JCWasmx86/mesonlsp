import SwiftTreeSitter

public final class SubscriptExpression: Expression {
  public let file: MesonSourceFile
  public var outer: Node
  public var inner: Node
  public var types: [Type] = []
  public let location: Location
  public weak var parent: Node?

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.location = Location(node: node)
    self.outer = from_tree(file: file, tree: node.namedChild(at: 0))!
    self.inner = from_tree(file: file, tree: node.namedChild(at: 1))!
  }
  fileprivate init(file: MesonSourceFile, location: Location, outer: Node, inner: Node) {
    self.file = file
    self.location = location
    self.outer = outer
    self.inner = inner
  }
  public func clone() -> Node {
    let location = self.location.clone()
    return SubscriptExpression(
      file: file,
      location: location,
      outer: self.outer.clone(),
      inner: self.inner.clone()
    )
  }
  public func visit(visitor: CodeVisitor) { visitor.visitSubscriptExpression(node: self) }
  public func visitChildren(visitor: CodeVisitor) {
    self.outer.visit(visitor: visitor)
    self.inner.visit(visitor: visitor)
  }

  public func setParents() {
    self.inner.parent = self
    self.outer.parent = self
    self.inner.setParents()
    self.outer.setParents()
  }
  public var description: String { return "(SubscriptExpression \(outer)[\(inner)])" }
}
