import SwiftTreeSitter

public final class IterationStatement: Statement {
  public let file: MesonSourceFile
  public var ids: [Node]
  public var expression: Node
  public var block: [Node]
  public var types: [Type] = []
  public let location: Location
  public weak var parent: Node?

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.location = Location(node: node)
    var idx = 2
    let idList = node.namedChild(at: 0)!
    var tmpIds: [Node] = []
    idList.enumerateNamedChildren { tmpIds.append(from_tree(file: file, tree: $0)!) }
    self.ids = tmpIds
    self.expression = from_tree(file: file, tree: node.namedChild(at: 1)!)!
    var bb: [Node] = []
    while idx < node.namedChildCount {
      if let s = from_tree(file: file, tree: node.namedChild(at: idx)!) { bb.append(s) }
      idx += 1
    }
    self.block = bb
  }
  fileprivate init(
    file: MesonSourceFile,
    location: Location,
    expression: Node,
    ids: [Node],
    block: [Node]
  ) {
    self.file = file
    self.location = location
    self.expression = expression
    self.ids = ids
    self.block = block
  }
  public func clone() -> Node {
    let location = self.location.clone()
    return IterationStatement(
      file: file,
      location: location,
      expression: self.expression.clone(),
      ids: Array(self.ids.map { $0.clone() }),
      block: Array(self.block.map { $0.clone() })
    )
  }
  public func visit(visitor: CodeVisitor) { visitor.visitIterationStatement(node: self) }
  public func visitChildren(visitor: CodeVisitor) {
    for arg in self.ids { arg.visit(visitor: visitor) }
    self.expression.visit(visitor: visitor)
    for arg in self.block { arg.visit(visitor: visitor) }
  }

  public func setParents() {
    for arg in self.ids {
      arg.parent = self
      arg.setParents()
    }
    self.expression.parent = self
    self.expression.setParents()
    for arg in self.block {
      arg.parent = self
      arg.setParents()
    }
  }

}
