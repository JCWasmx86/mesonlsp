import SwiftTreeSitter

// swiftlint:disable cyclomatic_complexity
public enum BinaryOperator {
  case plus
  case minus
  case mul
  case div
  case modulo
  case equalsEquals
  case notEquals
  case gt
  case lt
  case ge
  case le
  case IN
  case notIn
  case or
  case and

  static func fromString(str: String) -> BinaryOperator? {
    switch str {
    case "+": return .plus
    case "-": return .minus
    case "*": return .mul
    case "/": return .div
    case "%": return .modulo
    case "==": return .equalsEquals
    case "!=": return .notEquals
    case ">": return .gt
    case "<": return .lt
    case ">=": return .ge
    case "<=": return .le
    case "in": return .IN
    case "not in": return .notIn
    case "and": return .and
    case "or": return .or
    default: return nil
    }
  }
}
// swiftlint:enable cyclomatic_complexity

public final class BinaryExpression: Statement {
  public let file: MesonSourceFile
  public var lhs: Node
  public var rhs: Node
  public let op: BinaryOperator?
  public var types: [Type] = []
  public let location: Location
  public weak var parent: Node?

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.location = Location(node: node)
    self.lhs = from_tree(file: file, tree: node.namedChild(at: 0))!
    self.rhs = from_tree(file: file, tree: node.namedChild(at: node.namedChildCount == 2 ? 1 : 2))!
    let opNode = node.namedChildCount == 2 ? node.child(at: 1) : node.namedChild(at: 1)
    self.op = BinaryOperator.fromString(str: string_value(file: file, node: opNode!))
  }
  fileprivate init(
    file: MesonSourceFile,
    location: Location,
    lhs: Node,
    rhs: Node,
    op: BinaryOperator?
  ) {
    self.file = file
    self.location = location
    self.lhs = lhs
    self.rhs = rhs
    self.op = op
  }
  public func clone() -> Node {
    let location = self.location.clone()
    return Self(
      file: file,
      location: location,
      lhs: self.lhs.clone(),
      rhs: self.rhs.clone(),
      op: self.op
    )
  }
  public func visit(visitor: CodeVisitor) { visitor.visitBinaryExpression(node: self) }
  public func visitChildren(visitor: CodeVisitor) {
    self.lhs.visit(visitor: visitor)
    self.rhs.visit(visitor: visitor)
  }

  public func setParents() {
    self.lhs.parent = self
    self.rhs.parent = self
    self.rhs.setParents()
    self.lhs.setParents()
  }

  public var description: String {
    return "(BinaryExpression \(lhs) \(String(describing: op)) \(rhs))"
  }
}
