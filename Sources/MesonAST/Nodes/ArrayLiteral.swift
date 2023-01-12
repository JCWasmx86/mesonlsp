import SwiftTreeSitter

public class ArrayLiteral: Expression {
  public let file: MesonSourceFile
  public var args: [Node]
  public var types: [Type] = []
  public let location: Location
  public var parent: Node?

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.location = Location(node: node)
    var bb: [Node] = []
    node.enumerateNamedChildren(block: { bb.append(from_tree(file: file, tree: $0)!) })
    self.args = bb
  }
  public func visit(visitor: CodeVisitor) { visitor.visitArrayLiteral(node: self) }
  public func visitChildren(visitor: CodeVisitor) {
    for arg in self.args { arg.visit(visitor: visitor) }
  }

  public func setParents() {
    for var arg in self.args {
      arg.parent = self
      arg.setParents()
    }
  }
}
