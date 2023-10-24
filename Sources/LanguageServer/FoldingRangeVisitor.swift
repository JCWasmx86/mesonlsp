import Foundation
import LanguageServerProtocol
import Logging
import MesonAST

public class FoldingRangeVisitor: CodeVisitor {
  static let LOG = Logger(label: "LanguageServer::FoldingRangeVisitor")
  internal var ranges: [FoldingRange] = []

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
    if !node.block.isEmpty {
      self.ranges.append(
        FoldingRange(
          startLine: Int(node.location.startLine),
          endLine: Int(node.location.endLine - 1)
        )
      )
    }
  }

  public func visitAssignmentStatement(node: AssignmentStatement) {
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
