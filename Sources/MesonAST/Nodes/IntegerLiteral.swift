import SwiftTreeSitter

public final class IntegerLiteral: Expression {
  public let file: MesonSourceFile
  public let value: String
  public var types: [Type] = []
  public let location: Location
  public weak var parent: Node?

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.location = Location(node: node)
    self.value = string_value(file: file, node: node)
  }
  fileprivate init(file: MesonSourceFile, location: Location, value: String) {
    self.file = file
    self.location = location
    self.value = value
  }
  public func clone() -> Node {
    let location = self.location.clone()
    return IntegerLiteral(file: file, location: location, value: self.value)
  }
  public func visit(visitor: CodeVisitor) { visitor.visitIntegerLiteral(node: self) }
  public func visitChildren(visitor: CodeVisitor) {}
  public func setParents() {

  }
  public var description: String { return "(IntegerLiteral \(value))" }
}
