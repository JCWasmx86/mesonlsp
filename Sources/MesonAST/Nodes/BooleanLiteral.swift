import SwiftTreeSitter

public class BooleanLiteral: Expression {
  public let file: MesonSourceFile
  public let value: Bool
  public var types: [Type] = [BoolType()]
  public let location: Location

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.location = Location(node: node)
    self.value = string_value(file: file, node: node) == "true"
  }
  public func visit(visitor: CodeVisitor) { visitor.visitBooleanLiteral(node: self) }
  public func visitChildren(visitor: CodeVisitor) {}
}
