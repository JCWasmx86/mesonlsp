import LanguageServerProtocol
import MesonAST

public class InlayHintsCollector: CodeVisitor {
  public var inlays: [InlayHint] = []

  private func makeHint(_ id: Node) {
    let pos = Position(line: Int(id.location.startLine), utf16index: Int(id.location.endColumn))
    let text = ":" + prettify(id.types, 0)
    self.inlays.append(InlayHint(position: pos, label: .string(text)))
  }

  private func prettify(_ types: [Type], _ depth: Int) -> String {
    var strs: [String] = []
    for t in types {
      if t is Disabler && types.count > 1 { continue }
      if let lt = t as? ListType {
        if depth >= 1 {
          strs.append("list(...)")
        } else {
          strs.append("list(" + prettify(lt.types, depth + 1) + ")")
        }
      } else if let dt = t as? Dict {
        if depth >= 1 {
          strs.append("dict(...)")
        } else {
          strs.append("dict(" + prettify(dt.types, depth + 1) + ")")
        }
      } else if t is MesonAST.Subproject {
        strs.append("subproject")
      } else {
        strs.append(t.toString())
      }
    }
    return strs.sorted().joined(separator: "|")
  }

  public func visitSourceFile(file: SourceFile) { file.visitChildren(visitor: self) }

  public func visitBuildDefinition(node: BuildDefinition) { node.visitChildren(visitor: self) }

  public func visitErrorNode(node: ErrorNode) { node.visitChildren(visitor: self) }

  public func visitSelectionStatement(node: SelectionStatement) {
    node.visitChildren(visitor: self)
  }

  public func visitBreakStatement(node: BreakNode) { node.visitChildren(visitor: self) }

  public func visitContinueStatement(node: ContinueNode) { node.visitChildren(visitor: self) }

  public func visitIterationStatement(node: IterationStatement) {
    for id in node.ids { self.makeHint(id) }
    node.visitChildren(visitor: self)
  }

  public func visitAssignmentStatement(node: AssignmentStatement) {
    self.makeHint(node.lhs)
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

  public func visitIdExpression(node: IdExpression) { node.visitChildren(visitor: self) }

  public func visitBinaryExpression(node: BinaryExpression) { node.visitChildren(visitor: self) }

  public func visitStringLiteral(node: StringLiteral) { node.visitChildren(visitor: self) }

  public func visitArrayLiteral(node: ArrayLiteral) { node.visitChildren(visitor: self) }

  public func visitBooleanLiteral(node: BooleanLiteral) { node.visitChildren(visitor: self) }

  public func visitIntegerLiteral(node: IntegerLiteral) { node.visitChildren(visitor: self) }

  public func visitDictionaryLiteral(node: DictionaryLiteral) { node.visitChildren(visitor: self) }

  public func visitKeyValueItem(node: KeyValueItem) { node.visitChildren(visitor: self) }
}
