import SwiftTreeSitter

public class BuildDefinition: Node {
  public let file: MesonSourceFile
  public var stmts: [Node]

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    var s: [Node] = []
    node.enumerateNamedChildren(block: {
      if let n1 = from_tree(file: file, tree: $0) {
        s.append(n1)
      } else {
        // s.append(ErrorNode(file: file, node: $0, msg: "Unexpected failure to parse statement"))
      }
    })
    self.stmts = s
  }
  public func visit(visitor: CodeVisitor) {
    visitor.visitBuildDefinition(node: self)
  }
  public func visitChildren(visitor: CodeVisitor) {
    for arg in self.stmts {
      arg.visit(visitor: visitor)
    }
  }
}
