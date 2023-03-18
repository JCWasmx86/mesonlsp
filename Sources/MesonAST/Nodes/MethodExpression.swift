import SwiftTreeSitter

public final class MethodExpression: Expression {
  public let file: MesonSourceFile
  public var obj: Node
  public var id: Node
  public var argumentList: Node?
  public var types: [Type] = []
  public let location: Location
  public var method: Method?
  public weak var parent: Node?

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.location = Location(node: node)
    self.obj = from_tree(file: file, tree: node.namedChild(at: 0))!
    self.id = from_tree(file: file, tree: node.namedChild(at: 1))!
    if let nc = node.child(at: 4), nc.nodeType != ")" {
      self.argumentList = from_tree(file: file, tree: nc)
    }
  }
  fileprivate init(
    file: MesonSourceFile,
    location: Location,
    obj: Node,
    id: Node,
    argumentList: Node?
  ) {
    self.file = file
    self.location = location
    self.obj = obj
    self.id = id
    self.argumentList = argumentList
  }
  public func clone() -> Node {
    let location = self.location.clone()
    return Self(
      file: file,
      location: location,
      obj: self.obj.clone(),
      id: self.id.clone(),
      argumentList: self.argumentList == nil ? nil : self.argumentList!.clone()
    )
  }
  public func visit(visitor: CodeVisitor) { visitor.visitMethodExpression(node: self) }
  public func visitChildren(visitor: CodeVisitor) {
    self.obj.visit(visitor: visitor)
    self.id.visit(visitor: visitor)
    self.argumentList?.visit(visitor: visitor)
  }

  public func setParents() {
    self.obj.parent = self
    self.obj.setParents()
    self.id.parent = self
    self.id.setParents()
    self.argumentList?.parent = self
    self.argumentList?.setParents()
  }

  public var description: String {
    return "(MethodExpression \(obj).\(id) \(String(describing: argumentList)))"
  }
}
