import MesonAST
import PathKit

class ASTPatcher: CodeVisitor {
  public var subdirs: [String] = []
  public var subdirNodes: [SubdirCall] = []
  public var multiSubdirNodes: [MultiSubdirCall] = []
  private var parent: String = ""

  func isSubdirCall(node: Node) -> Bool {
    if let f = node as? FunctionExpression, let fid = f.id as? IdExpression, fid.id == "subdir",
      let alNode = f.argumentList, let al = alNode as? ArgumentList
    {
      let args = al.args
      for a in args where a is StringLiteral {
        if let sl = a as? StringLiteral {
          if !Path(parent + "/" + sl.contents() + "/meson.build").exists { return false }
          subdirs.append(sl.id)
          return true
        }
      }
    }
    return false
  }

  func isMultiSubdirCall(node: Node) -> Bool {
    if let f = node as? FunctionExpression, let fid = f.id as? IdExpression, fid.id == "subdir",
      let alNode = f.argumentList, let al = alNode as? ArgumentList
    {
      let args = al.args
      for a in args where a is IdExpression { return true }
    }
    return false
  }
  func visitSourceFile(file: SourceFile) {
    self.parent = Path(file.file.file).parent().description
    file.visitChildren(visitor: self)
  }
  func visitBuildDefinition(node: BuildDefinition) {
    var idx = 0
    var idxes: [Int] = []
    for stmt in node.stmts {
      if self.isSubdirCall(node: stmt) { idxes.append(idx) }
      idx += 1
    }
    for x in idxes {
      let stmt = node.stmts[x]
      let sc = SubdirCall(file: stmt.file, node: stmt as! FunctionExpression)
      node.stmts[x] = sc
      node.stmts[x].parent = node
      subdirNodes.append(sc)
    }
    idx = 0
    idxes = []
    for stmt in node.stmts {
      if self.isMultiSubdirCall(node: stmt) { idxes.append(idx) }
      idx += 1
    }
    for x in idxes {
      let stmt = node.stmts[x]
      let sc = MultiSubdirCall(file: stmt.file, node: stmt as! FunctionExpression)
      node.stmts[x] = sc
      node.stmts[x].parent = node
      multiSubdirNodes.append(sc)
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
          let sc = SubdirCall(file: stmt.file, node: stmt as! FunctionExpression)
          node.blocks[bidx][idx] = sc
          node.blocks[bidx][idx].parent = node
          subdirNodes.append(sc)
        } else if self.isMultiSubdirCall(node: b) {
          let stmt = node.blocks[bidx][idx]
          let sc = MultiSubdirCall(file: stmt.file, node: stmt as! FunctionExpression)
          node.blocks[bidx][idx] = sc
          node.blocks[bidx][idx].parent = node
          multiSubdirNodes.append(sc)
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
      let sc = SubdirCall(file: stmt.file, node: stmt as! FunctionExpression)
      node.block[x] = sc
      node.block[x].parent = node
      subdirNodes.append(sc)
    }
    idx = 0
    idxes = []
    for stmt in node.block {
      if self.isMultiSubdirCall(node: stmt) { idxes.append(idx) }
      idx += 1
    }
    for x in idxes {
      let stmt = node.block[x]
      let sc = MultiSubdirCall(file: stmt.file, node: stmt as! FunctionExpression)
      node.block[x] = sc
      node.block[x].parent = node
      multiSubdirNodes.append(sc)
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
