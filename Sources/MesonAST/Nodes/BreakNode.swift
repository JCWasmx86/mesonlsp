import SwiftTreeSitter

public class BreakNode: Statement {
  public let file: MesonSourceFile
  public var types: [Type] = []
  public let location: Location

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.location = Location(node: node)
  }
  public func visit(visitor: CodeVisitor) { visitor.visitBreakStatement(node: self) }
  public func visitChildren(visitor: CodeVisitor) {}
}
