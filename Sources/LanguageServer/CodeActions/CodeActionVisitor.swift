import LanguageServerProtocol
import Logging
import MesonAnalyze
import MesonAST

public class CodeActionVisitor: ExtendedCodeVisitor {
  static let LOG = Logger(label: "LanguageServer::CodeActionVisitor")
  var applicableNodes: [Node] = []
  private let range: Range<Position>

  public init(_ range: Range<Position>) { self.range = range }

  private func inRange(_ node: Node, _ add: Bool = true) -> Bool {
    let sP = Position(
      line: Int(node.location.startLine),
      utf16index: Int(node.location.startColumn)
    )
    let eP = Position(line: Int(node.location.endLine), utf16index: Int(node.location.endColumn))
    let r2 = sP...eP
    let pointsMatch = (self.range.contains(sP) || self.range.contains(eP))
    let rangesMatch = (r2.contains(self.range.lowerBound) && r2.contains(self.range.upperBound))
    if pointsMatch || rangesMatch {
      if add { self.applicableNodes.append(node) }
      Self.LOG.info("Found matching node: \(String(describing: type(of: node)))")
      return true
    }
    return false
  }

  public func visitSourceFile(file: SourceFile) { file.visitChildren(visitor: self) }
  public func visitBuildDefinition(node: BuildDefinition) {
    if self.inRange(node, false) { node.visitChildren(visitor: self) }
  }
  public func visitErrorNode(node: ErrorNode) {
    if self.inRange(node, false) { node.visitChildren(visitor: self) }
  }
  public func visitSelectionStatement(node: SelectionStatement) {
    if self.inRange(node) { node.visitChildren(visitor: self) }
  }
  public func visitBreakStatement(node: BreakNode) {
    if self.inRange(node) { node.visitChildren(visitor: self) }
  }
  public func visitContinueStatement(node: ContinueNode) {
    if self.inRange(node) { node.visitChildren(visitor: self) }
  }
  public func visitIterationStatement(node: IterationStatement) {
    if self.inRange(node) { node.visitChildren(visitor: self) }
  }
  public func visitAssignmentStatement(node: AssignmentStatement) {
    if self.inRange(node) { node.visitChildren(visitor: self) }
  }
  public func visitFunctionExpression(node: FunctionExpression) {
    if self.inRange(node) { node.visitChildren(visitor: self) }
  }
  public func visitArgumentList(node: ArgumentList) {
    if self.inRange(node) { node.visitChildren(visitor: self) }
  }
  public func visitKeywordItem(node: KeywordItem) {
    if self.inRange(node) { node.visitChildren(visitor: self) }
  }
  public func visitConditionalExpression(node: ConditionalExpression) {
    if self.inRange(node) { node.visitChildren(visitor: self) }
  }
  public func visitUnaryExpression(node: UnaryExpression) {
    if self.inRange(node) { node.visitChildren(visitor: self) }
  }
  public func visitSubscriptExpression(node: SubscriptExpression) {
    if self.inRange(node) { node.visitChildren(visitor: self) }
  }
  public func visitMethodExpression(node: MethodExpression) {
    if self.inRange(node) { node.visitChildren(visitor: self) }
  }
  public func visitIdExpression(node: IdExpression) {
    if self.inRange(node) { node.visitChildren(visitor: self) }
  }
  public func visitBinaryExpression(node: BinaryExpression) {
    if self.inRange(node) { node.visitChildren(visitor: self) }
  }
  public func visitStringLiteral(node: StringLiteral) {
    if self.inRange(node) { node.visitChildren(visitor: self) }
  }
  public func visitArrayLiteral(node: ArrayLiteral) {
    if self.inRange(node) { node.visitChildren(visitor: self) }
  }
  public func visitBooleanLiteral(node: BooleanLiteral) {
    if self.inRange(node) { node.visitChildren(visitor: self) }
  }
  public func visitIntegerLiteral(node: IntegerLiteral) {
    if self.inRange(node) { node.visitChildren(visitor: self) }
  }
  public func visitDictionaryLiteral(node: DictionaryLiteral) {
    if self.inRange(node) { node.visitChildren(visitor: self) }
  }
  public func visitKeyValueItem(node: KeyValueItem) {
    if self.inRange(node) { node.visitChildren(visitor: self) }
  }
  public func visitSubdirCall(node: SubdirCall) {
    if self.inRange(node) { node.visitChildren(visitor: self) }
  }
  public func visitMultiSubdirCall(node: MultiSubdirCall) {
    if self.inRange(node) { node.visitChildren(visitor: self) }
  }
}
