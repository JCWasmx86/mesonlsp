public protocol Node: AnyObject {
  var file: MesonSourceFile { get }
  var types: [Type] { get set }
  var location: Location { get }
  var parent: Node? { get set }
  func visit(visitor: CodeVisitor)
  func visitChildren(visitor: CodeVisitor)
  func setParents()
}

extension Node {
  public func equals(right: Node) -> Bool {
    let left = self
    return left.file.file == right.file.file && left.location.startLine == right.location.startLine
      && left.location.endLine == right.location.endLine
      && left.location.startColumn == right.location.startColumn
      && left.location.endColumn == right.location.endColumn
  }

}

public protocol Statement: Node {

}

public protocol Expression: Node {

}
