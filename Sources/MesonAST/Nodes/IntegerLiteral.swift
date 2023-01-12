import SwiftTreeSitter

public class IntegerLiteral: Expression {
  public let file: MesonSourceFile
  public let value: String
  public var types: [Type] = []
  public let location: Location
  public var parent: Node?

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.location = Location(node: node)
    self.value = string_value(file: file, node: node)
  }
  public func visit(visitor: CodeVisitor) { visitor.visitIntegerLiteral(node: self) }
  public func visitChildren(visitor: CodeVisitor) {}
  public func setParents() {

  }

}
