import MesonAnalyze
import MesonAST

internal final class NodeCounter: ExtendedCodeVisitor {
  internal var nodeCount: [String: UInt] = [:]

  private func countNode(_ node: Node) {
    let type = type(of: node)
    let name = String(describing: type)
    if self.nodeCount[name] == nil {
      self.nodeCount[name] = 1
    } else {
      self.nodeCount[name] = self.nodeCount[name]! + 1
    }
  }

  func visitSourceFile(file: SourceFile) {
    self.countNode(file)
    file.visitChildren(visitor: self)
  }
  func visitBuildDefinition(node: BuildDefinition) {
    self.countNode(node)
    node.visitChildren(visitor: self)
  }
  func visitErrorNode(node: ErrorNode) {
    self.countNode(node)
    node.visitChildren(visitor: self)
  }
  func visitSelectionStatement(node: SelectionStatement) {
    self.countNode(node)
    node.visitChildren(visitor: self)
  }
  func visitBreakStatement(node: BreakNode) {
    self.countNode(node)
    node.visitChildren(visitor: self)
  }
  func visitContinueStatement(node: ContinueNode) {
    self.countNode(node)
    node.visitChildren(visitor: self)
  }
  func visitIterationStatement(node: IterationStatement) {
    self.countNode(node)
    node.visitChildren(visitor: self)
  }
  func visitAssignmentStatement(node: AssignmentStatement) {
    self.countNode(node)
    node.visitChildren(visitor: self)
  }
  func visitFunctionExpression(node: FunctionExpression) {
    self.countNode(node)
    node.visitChildren(visitor: self)
  }
  func visitArgumentList(node: ArgumentList) {
    self.countNode(node)
    node.visitChildren(visitor: self)
  }
  func visitKeywordItem(node: KeywordItem) {
    self.countNode(node)
    node.visitChildren(visitor: self)
  }
  func visitConditionalExpression(node: ConditionalExpression) {
    self.countNode(node)
    node.visitChildren(visitor: self)
  }
  func visitUnaryExpression(node: UnaryExpression) {
    self.countNode(node)
    node.visitChildren(visitor: self)
  }
  func visitSubscriptExpression(node: SubscriptExpression) {
    self.countNode(node)
    node.visitChildren(visitor: self)
  }
  func visitMethodExpression(node: MethodExpression) {
    self.countNode(node)
    node.visitChildren(visitor: self)
  }
  func visitIdExpression(node: IdExpression) {
    self.countNode(node)
    node.visitChildren(visitor: self)
  }
  func visitBinaryExpression(node: BinaryExpression) {
    self.countNode(node)
    node.visitChildren(visitor: self)
  }
  func visitStringLiteral(node: StringLiteral) {
    self.countNode(node)
    node.visitChildren(visitor: self)
  }
  func visitArrayLiteral(node: ArrayLiteral) {
    self.countNode(node)
    node.visitChildren(visitor: self)
  }
  func visitBooleanLiteral(node: BooleanLiteral) {
    self.countNode(node)
    node.visitChildren(visitor: self)
  }
  func visitIntegerLiteral(node: IntegerLiteral) {
    self.countNode(node)
    node.visitChildren(visitor: self)
  }
  func visitDictionaryLiteral(node: DictionaryLiteral) {
    self.countNode(node)
    node.visitChildren(visitor: self)
  }
  func visitKeyValueItem(node: KeyValueItem) {
    self.countNode(node)
    node.visitChildren(visitor: self)
  }
  func visitSubdirCall(node: SubdirCall) {
    self.countNode(node)
    node.visitChildren(visitor: self)
    node.file_?.visit(visitor: self)
  }
  func visitMultiSubdirCall(node: MultiSubdirCall) {
    self.countNode(node)
    node.visitChildren(visitor: self)
    node.files.forEach { $0.visit(visitor: self) }
  }
}
