import SwiftTreeSitter

public final class BooleanLiteral: Expression {
  public let file: MesonSourceFile
  public let value: Bool
  public var types: [Type] = [BoolType()]
  public let location: Location
  public weak var parent: Node?

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.location = Location(node: node)
    self.value = string_value(file: file, node: node) == "true"
  }
  fileprivate init(file: MesonSourceFile, location: Location, value: Bool) {
    self.file = file
    self.location = location
    self.value = value
  }
  public func clone() -> Node {
    let location = self.location.clone()
    return BooleanLiteral(file: file, location: location, value: self.value)
  }
  public func visit(visitor: CodeVisitor) { visitor.visitBooleanLiteral(node: self) }
  public func visitChildren(visitor: CodeVisitor) {}
  public func setParents() {

  }

  public var description: String { return "(BooleanLiteral \(value))" }
}
