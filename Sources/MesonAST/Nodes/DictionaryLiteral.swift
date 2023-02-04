import SwiftTreeSitter

public class DictionaryLiteral: Expression {
  public let file: MesonSourceFile
  public let values: [Node]
  public var types: [Type] = []
  public let location: Location
  public weak var parent: Node?

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.location = Location(node: node)
    var bb: [Node] = []
    node.enumerateNamedChildren(block: { bb.append(from_tree(file: file, tree: $0)!) })
    self.values = bb
  }
  public func visit(visitor: CodeVisitor) { visitor.visitDictionaryLiteral(node: self) }
  public func visitChildren(visitor: CodeVisitor) {
    for arg in self.values { arg.visit(visitor: visitor) }
  }

  public func setParents() {
    for arg in self.values {
      arg.parent = self
      arg.setParents()
    }
  }
  public var description: String { return "(DictionaryLiteral \(values))" }
}
