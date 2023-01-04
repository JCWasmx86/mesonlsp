import SwiftTreeSitter

public class SourceFile: Node {
  public let file: MesonSourceFile
  public let build_definition: Node

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    if node.namedChildCount == 0 {
      self.build_definition = ErrorNode(
        file: file, node: node, msg: "Expected build_definition, got nothing!")
      return
    }
    if node.namedChildCount != 1 {
      self.build_definition = ErrorNode(
        file: file, node: node, msg: "Got too many children of a sourcefile!")
      return
    }
    if node.namedChild(at: 0)?.nodeType == "build_definition" {
      self.build_definition = BuildDefinition(file: file, node: node.namedChild(at: 0)!)
    } else {
      let nodeType = node.namedChild(at: 0)?.nodeType
      self.build_definition = ErrorNode(
        file: file, node: node.namedChild(at: 0)!,
        msg: "Expected build_definition, got \(nodeType!)")
    }
  }
  public func visit(visitor: CodeVisitor) {
    visitor.visitSourceFile(file: self)
  }
  public func visitChildren(visitor: CodeVisitor) {
    self.build_definition.visit(visitor: visitor)
  }
}
