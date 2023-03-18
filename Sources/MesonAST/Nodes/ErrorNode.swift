import SwiftTreeSitter

public final class ErrorNode: Node {
  public let file: MesonSourceFile
  public let message: String
  public var types: [Type] = []
  public let location: Location
  public weak var parent: Node?

  init(file: MesonSourceFile, msg: String) {
    self.file = file
    self.message = msg
    self.location = Location()
  }
  init(file: MesonSourceFile, node: SwiftTreeSitter.Node, msg: String) {
    self.file = file
    self.location = Location(node: node)
    self.message = msg
  }
  fileprivate init(file: MesonSourceFile, location: Location, msg: String) {
    self.file = file
    self.location = location
    self.message = msg
  }
  public func clone() -> Node {
    let location = self.location.clone()
    return ErrorNode(file: file, location: location, msg: self.message)
  }
  public func visit(visitor: CodeVisitor) { visitor.visitErrorNode(node: self) }
  public func visitChildren(visitor: CodeVisitor) {}
  public func setParents() {

  }

  public var description: String { return "(ErrorNode \(message))" }
}
