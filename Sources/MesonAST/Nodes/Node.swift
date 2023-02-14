public protocol Node: AnyObject, CustomStringConvertible {
  var file: MesonSourceFile { get }
  var types: [Type] { get set }
  var location: Location { get }
  var parent: Node? { get set }
  func visit(visitor: CodeVisitor)
  func visitChildren(visitor: CodeVisitor)
  func setParents()
  func clone() -> Node
}

extension Node {
  public func equals(right: Node) -> Bool {
    let left = self
    return left.file.file == right.file.file && left.location.startLine == right.location.startLine
      && left.location.endLine == right.location.endLine
      && left.location.startColumn == right.location.startColumn
      && left.location.endColumn == right.location.endColumn
  }
  public var description: String { return "<<>>" }
}

public protocol Statement: Node {

}

public protocol Expression: Node {

}
