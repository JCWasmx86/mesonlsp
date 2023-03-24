import IOUtils
import MesonAST

class ASTPatcher: CodeVisitor {
  public var subdirs: [String] = []
  public var subdirNodes: [SubdirCall] = []
  public var multiSubdirNodes: [MultiSubdirCall] = []
  private var parent: String = ""

  private func isSubdirCall(node: Node) -> Bool {
    if let f = node as? FunctionExpression, let fid = f.id as? IdExpression, fid.id == "subdir",
      let alNode = f.argumentList, let al = alNode as? ArgumentList
    {
      let args = al.args
      for a in args where a is StringLiteral {
        if let sl = a as? StringLiteral {
          if !Path(parent + Path.separator + sl.contents() + "\(Path.separator)meson.build").exists
          {
            return false
          }
          subdirs.append(sl.id)
          return true
        }
      }
    }
    return false
  }

  private func isMultiSubdirCall(node: Node) -> Bool {
    if let f = node as? FunctionExpression, let fid = f.id as? IdExpression, fid.id == "subdir",
      let alNode = f.argumentList, let al = alNode as? ArgumentList
    {
      let args = al.args
      for a in args where !(a is StringLiteral) { return true }
    }
    return false
  }

  func visitSourceFile(file: SourceFile) {
    self.parent = Path(file.file.file).parent().description
    file.visitChildren(visitor: self)
  }

  func visitBuildDefinition(node: BuildDefinition) {
    var idx = 0
    for stmt in node.stmts {
      if self.isSubdirCall(node: stmt) {
        let sc = SubdirCall(file: stmt.file, node: stmt as! FunctionExpression)
        node.stmts[idx] = sc
        node.stmts[idx].parent = node
        subdirNodes.append(sc)
      } else if self.isMultiSubdirCall(node: stmt) {
        let sc = MultiSubdirCall(file: stmt.file, node: stmt as! FunctionExpression)
        node.stmts[idx] = sc
        node.stmts[idx].parent = node
        multiSubdirNodes.append(sc)
      }
      idx += 1
    }
    node.visitChildren(visitor: self)
  }

  func visitErrorNode(node: ErrorNode) {}

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

  func visitBreakStatement(node: BreakNode) {}

  func visitContinueStatement(node: ContinueNode) {}

  func visitIterationStatement(node: IterationStatement) {
    var idx = 0
    for stmt in node.block {
      if self.isSubdirCall(node: stmt) {
        let sc = SubdirCall(file: stmt.file, node: stmt as! FunctionExpression)
        node.block[idx] = sc
        node.block[idx].parent = node
        subdirNodes.append(sc)
      } else if self.isMultiSubdirCall(node: stmt) {
        let sc = MultiSubdirCall(file: stmt.file, node: stmt as! FunctionExpression)
        node.block[idx] = sc
        node.block[idx].parent = node
        multiSubdirNodes.append(sc)
      }
      idx += 1
    }
    node.visitChildren(visitor: self)
  }

  func visitAssignmentStatement(node: AssignmentStatement) {}

  func visitFunctionExpression(node: FunctionExpression) {}

  func visitArgumentList(node: ArgumentList) {}

  func visitKeywordItem(node: KeywordItem) {}

  func visitConditionalExpression(node: ConditionalExpression) {}

  func visitUnaryExpression(node: UnaryExpression) {}

  func visitSubscriptExpression(node: SubscriptExpression) {}

  func visitMethodExpression(node: MethodExpression) {}

  func visitIdExpression(node: IdExpression) {}

  func visitBinaryExpression(node: BinaryExpression) {}

  func visitStringLiteral(node: StringLiteral) {}

  func visitArrayLiteral(node: ArrayLiteral) {}

  func visitBooleanLiteral(node: BooleanLiteral) {}

  func visitIntegerLiteral(node: IntegerLiteral) {}

  func visitDictionaryLiteral(node: DictionaryLiteral) {}

  func visitKeyValueItem(node: KeyValueItem) {}
}
