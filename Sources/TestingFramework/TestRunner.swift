import Logging
import MesonAnalyze
import MesonAST

public class TestRunner: ExtendedCodeVisitor {
  static let LOG = Logger(label: "TestFramework::TestRunner")
  let assertions: [String: [AssertionCheck]]
  let metadata: MesonMetadata?
  public var failures = 0
  public var successes = 0
  public var notRun = 0
  public init(tree: MesonTree, assertions: [String: [AssertionCheck]]) {
    self.assertions = assertions
    if let a = tree.ast {
      self.metadata = tree.metadata
      a.visit(visitor: self)
      for file in self.assertions.keys {
        for checker in self.assertions[file]! where checker.isPostCheck() {
          if checker.postCheck(metadata: self.metadata!, scope: tree.scope!) == .success {
            TestRunner.LOG.info("Successful: \(checker.formatMessage())")
            self.successes += 1
          } else {
            TestRunner.LOG.error("Failed: \(checker.formatMessage())")
            self.failures += 1
          }
        }
      }
      TestRunner.LOG.info(
        "\(tree.file): Tests: \(self.successes)/\(self.successes + self.failures) passed"
      )
      notRun = assertions.flatMap({ $0.value }).count - (failures + successes)
    } else {
      self.metadata = nil
    }
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
    node.visitChildren(visitor: self)
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
  public func visitSubdirCall(node: SubdirCall) { node.visitChildren(visitor: self) }
}
