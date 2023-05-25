import Foundation
import IOUtils
import LanguageServerProtocol
import MesonAnalyze
import MesonAST

internal class LoopVariableRename: ExtendedCodeVisitor {
  internal var edits: [DocumentURI: [TextEdit]] = [:]
  private let oldName: String
  private let newName: String

  internal init(_ oldName: String, _ newName: String) {
    self.oldName = oldName
    self.newName = newName
  }

  func visitSubdirCall(node: MesonAnalyze.SubdirCall) { node.visitChildren(visitor: self) }

  func visitMultiSubdirCall(node: MesonAnalyze.MultiSubdirCall) {
    node.visitChildren(visitor: self)
  }

  func visitSourceFile(file: MesonAST.SourceFile) { file.visitChildren(visitor: self) }

  func visitBuildDefinition(node: MesonAST.BuildDefinition) { node.visitChildren(visitor: self) }

  func visitErrorNode(node: MesonAST.ErrorNode) { node.visitChildren(visitor: self) }

  func visitSelectionStatement(node: MesonAST.SelectionStatement) {
    node.visitChildren(visitor: self)
  }

  func visitBreakStatement(node: MesonAST.BreakNode) { node.visitChildren(visitor: self) }

  func visitContinueStatement(node: MesonAST.ContinueNode) { node.visitChildren(visitor: self) }

  func visitIterationStatement(node: MesonAST.IterationStatement) {
    node.visitChildren(visitor: self)
  }

  func visitAssignmentStatement(node: MesonAST.AssignmentStatement) {
    node.visitChildren(visitor: self)
  }

  func visitFunctionExpression(node: MesonAST.FunctionExpression) {
    node.visitChildren(visitor: self)
  }

  func visitArgumentList(node: MesonAST.ArgumentList) { node.visitChildren(visitor: self) }

  func visitKeywordItem(node: MesonAST.KeywordItem) { node.visitChildren(visitor: self) }

  func visitConditionalExpression(node: MesonAST.ConditionalExpression) {
    node.visitChildren(visitor: self)
  }

  func visitUnaryExpression(node: MesonAST.UnaryExpression) { node.visitChildren(visitor: self) }

  func visitSubscriptExpression(node: MesonAST.SubscriptExpression) {
    node.visitChildren(visitor: self)
  }

  func visitMethodExpression(node: MesonAST.MethodExpression) { node.visitChildren(visitor: self) }

  func visitIdExpression(node: MesonAST.IdExpression) {
    node.visitChildren(visitor: self)
    if node.id != self.oldName { return }
    // Don't rename functions/keyword arguments'
    if let kw = node.parent as? KeywordItem, kw.key.equals(right: node) { return }
    if let fn = node.parent as? FunctionExpression, fn.id.equals(right: node) { return }
    if let fn = node.parent as? MethodExpression, fn.id.equals(right: node) { return }
    let d = DocumentURI(
      URL(fileURLWithPath: Path(node.file.file).normalize().absolute().description)
    )
    let range = Shared.nodeToRange(node)
    let textEdit = TextEdit(range: range, newText: newName)
    self.edits[d] = (self.edits[d] ?? []) + [textEdit]
  }

  func visitBinaryExpression(node: MesonAST.BinaryExpression) { node.visitChildren(visitor: self) }

  func visitStringLiteral(node: MesonAST.StringLiteral) { node.visitChildren(visitor: self) }

  func visitArrayLiteral(node: MesonAST.ArrayLiteral) { node.visitChildren(visitor: self) }

  func visitBooleanLiteral(node: MesonAST.BooleanLiteral) { node.visitChildren(visitor: self) }

  func visitIntegerLiteral(node: MesonAST.IntegerLiteral) { node.visitChildren(visitor: self) }

  func visitDictionaryLiteral(node: MesonAST.DictionaryLiteral) {
    node.visitChildren(visitor: self)
  }

  func visitKeyValueItem(node: MesonAST.KeyValueItem) { node.visitChildren(visitor: self) }

}
