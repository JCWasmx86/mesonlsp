import SwiftTreeSitter

public enum UnaryOperator {
  case not
  case exclamationMark
  case minus
  static func fromString(str: String) -> UnaryOperator? {
    switch str {
    case "not":
      return .not
    case "!":
      return .exclamationMark
    case "-":
      return .minus
    default:
      return nil
    }
  }
}
public class UnaryExpression: Expression {
  public let file: MesonSourceFile
  public let expression: Node
  public let op: UnaryOperator?

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.expression = from_tree(file: file, tree: node.namedChild(at: 0))!
    self.op = UnaryOperator.fromString(str: string_value(file: file, node: node.child(at: 0)!))
  }
  public func visit(visitor: CodeVisitor) {
    visitor.visitUnaryExpression(node: self)
  }
  public func visitChildren(visitor: CodeVisitor) {
    self.expression.visit(visitor: visitor)
  }
}
