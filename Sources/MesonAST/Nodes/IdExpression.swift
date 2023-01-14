import SwiftTreeSitter

public class IdExpression: Expression {
  public let file: MesonSourceFile
  public let id: String
  public var types: [Type] = []
  public let location: Location
  public weak var parent: Node?

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.location = Location(node: node)
    self.id = string_value(file: file, node: node)
  }
  public func visit(visitor: CodeVisitor) { visitor.visitIdExpression(node: self) }
  public func visitChildren(visitor: CodeVisitor) {}
  public func setParents() {

  }

}
