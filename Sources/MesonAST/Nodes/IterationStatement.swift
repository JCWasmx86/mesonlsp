import SwiftTreeSitter

public class IterationStatement: Statement {
  public let file: MesonSourceFile
  public let ids: [Node]
  public let expression: Node
  public var block: [Node]

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    var idx = 2
    let idList = node.namedChild(at: 0)!
    var tmpIds: [Node] = []
    idList.enumerateNamedChildren(block: {
      tmpIds.append(from_tree(file: file, tree: $0)!)
    })
    self.ids = tmpIds
    self.expression = from_tree(file: file, tree: node.namedChild(at: 1)!)!
    var bb: [Node] = []
    while idx < node.namedChildCount {
      if let s = from_tree(file: file, tree: node.namedChild(at: idx)!) {
        bb.append(s)
      }
      idx += 1
    }
    self.block = bb
  }

  public func visit(visitor: CodeVisitor) {
    visitor.visitIterationStatement(node: self)
  }
  public func visitChildren(visitor: CodeVisitor) {
    for arg in self.ids {
      arg.visit(visitor: visitor)
    }
    self.expression.visit(visitor: visitor)
    for arg in self.block {
      arg.visit(visitor: visitor)
    }
  }
}
