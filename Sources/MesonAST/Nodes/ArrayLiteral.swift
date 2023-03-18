import SwiftTreeSitter

public final class ArrayLiteral: Expression {
  public let file: MesonSourceFile
  public var args: [Node]
  public var types: [Type] = []
  public let location: Location
  public weak var parent: Node?

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.location = Location(node: node)
    var bb: [Node] = []
    node.enumerateNamedChildren { bb.append(from_tree(file: file, tree: $0)!) }
    self.args = bb
  }
  fileprivate init(file: MesonSourceFile, location: Location, args: [Node]) {
    self.file = file
    self.location = location
    self.args = args
  }
  public func clone() -> Node {
    let newArgs: [Node] = Array(self.args.map { $0.clone() })
    let location = self.location.clone()
    return Self(file: file, location: location, args: newArgs)
  }
  public func visit(visitor: CodeVisitor) { visitor.visitArrayLiteral(node: self) }
  public func visitChildren(visitor: CodeVisitor) {
    for arg in self.args { arg.visit(visitor: visitor) }
  }

  public func setParents() {
    for arg in self.args {
      arg.parent = self
      arg.setParents()
    }
  }

  public var description: String { return "(ArrayLiteral \(args))" }
}
