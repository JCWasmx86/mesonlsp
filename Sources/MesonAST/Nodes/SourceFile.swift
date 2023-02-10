import SwiftTreeSitter

public class SourceFile: Node {
  public let file: MesonSourceFile
  var build_definition: Node?
  public var types: [Type] = []
  public let location: Location
  public weak var parent: Node?
  var errs: [Node] = []

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.location = Location(node: node)
    if node.namedChildCount == 0 {
      self.build_definition = nil
      return
    }
    if node.namedChildCount == 1 && node.namedChild(at: 0)?.nodeType == "build_definition" {
      self.build_definition = BuildDefinition(file: file, node: node.namedChild(at: 0)!)
      return
    }
    self.build_definition = ErrorNode(file: file, node: node, msg: "Missing build_definition")
    for n in 0..<node.namedChildCount {
      if node.namedChild(at: n)?.nodeType == "build_definition" {
        self.build_definition = BuildDefinition(file: file, node: node.namedChild(at: n)!)
      } else {
        self.errs.append(
          ErrorNode(file: file, node: node.namedChild(at: n)!, msg: "Unexpected child")
        )
      }
    }
  }
  public func visit(visitor: CodeVisitor) { visitor.visitSourceFile(file: self) }
  public func visitChildren(visitor: CodeVisitor) {
    self.build_definition?.visit(visitor: visitor)

    for e in self.errs { e.visit(visitor: visitor) }
  }
  public func setParents() {
    self.build_definition?.parent = self
    self.build_definition?.setParents()
    for e in errs {
      e.parent = self
      e.setParents()
    }
  }
}
