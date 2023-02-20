import MesonAST

public class HighlightSearcher: CodeVisitor {
  public var accesses: [(Int, Location)] = []
  private var varname: String

  public init(varname: String) { self.varname = varname }

  public func visitSourceFile(file: SourceFile) { file.visitChildren(visitor: self) }
  public func visitBuildDefinition(node: BuildDefinition) { node.visitChildren(visitor: self) }
  public func visitErrorNode(node: ErrorNode) { node.visitChildren(visitor: self) }
  public func visitSelectionStatement(node: SelectionStatement) {
    node.visitChildren(visitor: self)
  }
  public func visitBreakStatement(node: BreakNode) { node.visitChildren(visitor: self) }
  public func visitContinueStatement(node: ContinueNode) { node.visitChildren(visitor: self) }
  public func visitIterationStatement(node: IterationStatement) {
    node.visitChildren(visitor: self)
  }
  public func visitAssignmentStatement(node: AssignmentStatement) {
    if node.lhs is IdExpression, let lhs = node.lhs as? IdExpression, lhs.id == self.varname {
      self.accesses.append((3, lhs.location))
      node.rhs.visitChildren(visitor: self)
      return
    } else if node.lhs is SubscriptExpression, let lhs = node.lhs as? SubscriptExpression,
      let outer = lhs.outer as? IdExpression, outer.id == self.varname
    {
      self.accesses.append((3, lhs.location))
      node.rhs.visitChildren(visitor: self)
    }
    node.visitChildren(visitor: self)
  }
  public func visitFunctionExpression(node: FunctionExpression) {
    node.visitChildren(visitor: self)
  }
  public func visitArgumentList(node: ArgumentList) { node.visitChildren(visitor: self) }
  public func visitKeywordItem(node: KeywordItem) { node.visitChildren(visitor: self) }
  public func visitConditionalExpression(node: ConditionalExpression) {
    node.visitChildren(visitor: self)
  }
  public func visitUnaryExpression(node: UnaryExpression) { node.visitChildren(visitor: self) }
  public func visitSubscriptExpression(node: SubscriptExpression) {
    node.visitChildren(visitor: self)
  }
  public func visitMethodExpression(node: MethodExpression) { node.visitChildren(visitor: self) }
  public func visitIdExpression(node: IdExpression) {
    node.visitChildren(visitor: self)
    if node.id == varname { self.accesses.append((2, node.location)) }
  }
  public func visitBinaryExpression(node: BinaryExpression) { node.visitChildren(visitor: self) }
  public func visitStringLiteral(node: StringLiteral) { node.visitChildren(visitor: self) }
  public func visitArrayLiteral(node: ArrayLiteral) { node.visitChildren(visitor: self) }
  public func visitBooleanLiteral(node: BooleanLiteral) { node.visitChildren(visitor: self) }
  public func visitIntegerLiteral(node: IntegerLiteral) { node.visitChildren(visitor: self) }
  public func visitDictionaryLiteral(node: DictionaryLiteral) { node.visitChildren(visitor: self) }
  public func visitKeyValueItem(node: KeyValueItem) { node.visitChildren(visitor: self) }
}
