import SwiftTreeSitter

open class FunctionExpression: Expression {
  public var file: MesonSourceFile
  public var id: Node
  public var argumentList: Node?
  public var types: [Type] = []
  public var location: Location
  public var function: Function?
  public weak var parent: Node?

  public init() {
    self.file = MesonSourceFile(file: "/dev/stdin")
    self.id = ErrorNode(file: file, msg: "OOPS")
    self.argumentList = ErrorNode(file: file, msg: "OOPS")
    self.location = Location()
  }

  public init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.location = Location(node: node)
    self.id = from_tree(file: file, tree: node.namedChild(at: 0))!
    self.argumentList =
      node.namedChildCount == 1 ? nil : from_tree(file: file, tree: node.namedChild(at: 1))
  }
  fileprivate init(file: MesonSourceFile, location: Location, id: Node, argumentList: Node?) {
    self.file = file
    self.location = location
    self.id = id
    self.argumentList = argumentList
  }
  public func clone() -> Node {
    let location = self.location.clone()
    return FunctionExpression(
      file: file,
      location: location,
      id: self.id.clone(),
      argumentList: self.argumentList == nil ? nil : self.argumentList!.clone()
    )
  }
  open func visit(visitor: CodeVisitor) { visitor.visitFunctionExpression(node: self) }
  open func visitChildren(visitor: CodeVisitor) {
    self.id.visit(visitor: visitor)
    self.argumentList?.visit(visitor: visitor)
  }

  public func functionName() -> String {
    if let id = self.id as? IdExpression { return id.id }
    return "<<Error>>"
  }
  open func setParents() {
    self.id.parent = self
    self.id.setParents()
    self.argumentList?.parent = self
    self.argumentList?.setParents()
  }
  public var description: String {
    return "(FunctionExpression \(id) \(String(describing: self.argumentList)))"
  }
}
