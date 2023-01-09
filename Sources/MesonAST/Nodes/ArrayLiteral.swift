import SwiftTreeSitter

public class ArrayLiteral: Expression {
  public let file: MesonSourceFile
  public let args: [Node]
  public var types: [Type] = []

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    var bb: [Node] = []
    node.enumerateNamedChildren(block: {
      bb.append(from_tree(file: file, tree: $0)!)
    })
    self.args = bb
  }
  public func visit(visitor: CodeVisitor) {
    visitor.visitArrayLiteral(node: self)
  }
  public func visitChildren(visitor: CodeVisitor) {
    for arg in self.args {
      arg.visit(visitor: visitor)
    }
  }
}
