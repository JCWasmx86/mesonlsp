public protocol Node {
  var file: MesonSourceFile { get }
  var types: [Type] { get set }
  var location: Location { get }
  var parent: Node? { get set }
  func visit(visitor: CodeVisitor)
  func visitChildren(visitor: CodeVisitor)
  func setParents()
}

public protocol Statement: Node {

}

public protocol Expression: Node {

}
