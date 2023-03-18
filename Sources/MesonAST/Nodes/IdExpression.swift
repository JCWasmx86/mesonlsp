import SwiftTreeSitter

public final class IdExpression: Expression {
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
  fileprivate init(file: MesonSourceFile, location: Location, id: String) {
    self.file = file
    self.location = location
    self.id = id
  }
  public func clone() -> Node {
    let location = self.location.clone()
    return Self(file: file, location: location, id: self.id)
  }
  public func visit(visitor: CodeVisitor) { visitor.visitIdExpression(node: self) }
  public func visitChildren(visitor: CodeVisitor) {}
  public func setParents() {

  }

  public var description: String { return "(IdExpression \(id))" }
}
