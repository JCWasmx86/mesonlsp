import MesonAST

class ASTPatcher: CodeVisitor {
  public var subdirs: [String] = []
  func isSubdirCall(node: Node) -> Bool {
    if !(node is FunctionExpression) { return false }
    let f = node as! FunctionExpression
    if (f.id as! IdExpression).id != "subdir" { return false }
    if f.argumentList == nil || !(f.argumentList! is ArgumentList) { return false }
    let args = (f.argumentList! as! ArgumentList).args
    for a in args where a is StringLiteral {
      subdirs.append((a as! StringLiteral).id)
      return true
    }
    return false
  }
  func visitSourceFile(file: SourceFile) { file.visitChildren(visitor: self) }
  func visitBuildDefinition(node: BuildDefinition) {
    var idx = 0
    var idxes: [Int] = []
    for stmt in node.stmts {
      if self.isSubdirCall(node: stmt) { idxes.append(idx) }
      idx += 1
    }
    for x in idxes {
      let stmt = node.stmts[x]
      node.stmts[x] = SubdirCall(file: stmt.file, node: stmt as! FunctionExpression)
    }
    node.visitChildren(visitor: self)
  }
  func visitErrorNode(node: ErrorNode) { node.visitChildren(visitor: self) }
  func visitSelectionStatement(node: SelectionStatement) {
    var bidx = 0
    for bb in node.blocks {
      var idx = 0
      for b in bb {
        if self.isSubdirCall(node: b) {
          let stmt = node.blocks[bidx][idx]
          node.blocks[bidx][idx] = SubdirCall(file: stmt.file, node: stmt as! FunctionExpression)
        }
        idx += 1
      }
      bidx += 1
    }
    node.visitChildren(visitor: self)
  }
  func visitBreakStatement(node: BreakNode) { node.visitChildren(visitor: self) }
  func visitContinueStatement(node: ContinueNode) { node.visitChildren(visitor: self) }
  func visitIterationStatement(node: IterationStatement) {
    var idx = 0
    var idxes: [Int] = []
    for stmt in node.block {
      if self.isSubdirCall(node: stmt) { idxes.append(idx) }
      idx += 1
    }
    for x in idxes {
      let stmt = node.block[x]
      node.block[x] = SubdirCall(file: stmt.file, node: stmt as! FunctionExpression)
    }
    node.visitChildren(visitor: self)
  }
  func visitAssignmentStatement(node: AssignmentStatement) { node.visitChildren(visitor: self) }
  func visitFunctionExpression(node: FunctionExpression) { node.visitChildren(visitor: self) }
  func visitArgumentList(node: ArgumentList) { node.visitChildren(visitor: self) }
  func visitKeywordItem(node: KeywordItem) { node.visitChildren(visitor: self) }
  func visitConditionalExpression(node: ConditionalExpression) { node.visitChildren(visitor: self) }
  func visitUnaryExpression(node: UnaryExpression) { node.visitChildren(visitor: self) }
  func visitSubscriptExpression(node: SubscriptExpression) { node.visitChildren(visitor: self) }
  func visitMethodExpression(node: MethodExpression) { node.visitChildren(visitor: self) }
  func visitIdExpression(node: IdExpression) { node.visitChildren(visitor: self) }
  func visitBinaryExpression(node: BinaryExpression) { node.visitChildren(visitor: self) }
  func visitStringLiteral(node: StringLiteral) { node.visitChildren(visitor: self) }
  func visitArrayLiteral(node: ArrayLiteral) { node.visitChildren(visitor: self) }
  func visitBooleanLiteral(node: BooleanLiteral) { node.visitChildren(visitor: self) }
  func visitIntegerLiteral(node: IntegerLiteral) { node.visitChildren(visitor: self) }
  func visitDictionaryLiteral(node: DictionaryLiteral) { node.visitChildren(visitor: self) }
  func visitKeyValueItem(node: KeyValueItem) { node.visitChildren(visitor: self) }
}
