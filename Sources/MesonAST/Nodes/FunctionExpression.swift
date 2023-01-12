import SwiftTreeSitter

open class FunctionExpression: Expression {
  public var file: MesonSourceFile
  public var id: Node
  public var argumentList: Node?
  public var types: [Type] = []
  public var location: Location
  public var function: Function?
  public var parent: Node?

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
  open func visit(visitor: CodeVisitor) { visitor.visitFunctionExpression(node: self) }
  open func visitChildren(visitor: CodeVisitor) {
    self.id.visit(visitor: visitor)
    self.argumentList?.visit(visitor: visitor)
  }

  public func functionName() -> String {
    if self.id is IdExpression { return (self.id as! IdExpression).id }
    return "<<Error>>"
  }
  public func setParents() {
    self.id.parent = self
    self.id.setParents()
    self.argumentList?.parent = self
    self.argumentList?.setParents()
  }

}
