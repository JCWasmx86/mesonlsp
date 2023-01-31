import MesonAST

public class SymbolCodeVisitor: CodeVisitor {
  public var symbols: [Symbol] = []

  public init() {}
  public func visitSourceFile(file: SourceFile) { file.visitChildren(visitor: self) }
  public func visitBuildDefinition(node: BuildDefinition) { node.visitChildren(visitor: self) }
  public func visitErrorNode(node: ErrorNode) {}
  public func visitSelectionStatement(node: SelectionStatement) {
    node.visitChildren(visitor: self)
  }
  public func visitBreakStatement(node: BreakNode) {}
  public func visitContinueStatement(node: ContinueNode) {}
  public func visitIterationStatement(node: IterationStatement) {
    for id in node.ids where id is IdExpression {
      self.symbols.append(Symbol(id: id as! IdExpression))
    }
    node.visitChildren(visitor: self)
  }
  public func visitAssignmentStatement(node: AssignmentStatement) {
    if let op = node.op, op == .equals, let id = node.lhs as? IdExpression {
      self.symbols.append(Symbol(id: id))
    }
  }
  public func visitFunctionExpression(node: FunctionExpression) {}
  public func visitArgumentList(node: ArgumentList) {}
  public func visitKeywordItem(node: KeywordItem) {}
  public func visitConditionalExpression(node: ConditionalExpression) {}
  public func visitUnaryExpression(node: UnaryExpression) {}
  public func visitSubscriptExpression(node: SubscriptExpression) {}
  public func visitMethodExpression(node: MethodExpression) {}
  public func visitIdExpression(node: IdExpression) {}
  public func visitBinaryExpression(node: BinaryExpression) {}
  public func visitStringLiteral(node: StringLiteral) {}
  public func visitArrayLiteral(node: ArrayLiteral) {}
  public func visitBooleanLiteral(node: BooleanLiteral) {}
  public func visitIntegerLiteral(node: IntegerLiteral) {}
  public func visitDictionaryLiteral(node: DictionaryLiteral) {}
  public func visitKeyValueItem(node: KeyValueItem) {}
}
