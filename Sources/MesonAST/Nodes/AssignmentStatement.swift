import SwiftTreeSitter

public enum AssignmentOperator {
  case equals
  case mulequals
  case divequals
  case modequals
  case plusequals
  case minusequals

  static func fromString(str: String) -> AssignmentOperator? {
    switch str {
    case "=": return .equals
    case "*=": return .mulequals
    case "/=": return .divequals
    case "%=": return .modequals
    case "+=": return .plusequals
    case "-=": return .minusequals
    default: return nil
    }
  }
}

public class AssignmentStatement: Statement {
  public let file: MesonSourceFile
  public var lhs: Node
  public var rhs: Node
  public let op: AssignmentOperator?
  public var types: [Type] = []
  public let location: Location
  public weak var parent: Node?

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.location = Location(node: node)
    self.lhs = from_tree(file: file, tree: node.namedChild(at: 0))!
    self.rhs = from_tree(file: file, tree: node.namedChild(at: 2))!
    self.op = AssignmentOperator.fromString(
      str: string_value(file: file, node: node.namedChild(at: 1)!))
  }
  public func visit(visitor: CodeVisitor) { visitor.visitAssignmentStatement(node: self) }
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
  public var description: String { return "(AssignmentStatement \(lhs) \(op) \(rhs))" }
}
