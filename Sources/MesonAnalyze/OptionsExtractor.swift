import MesonAST

public class OptionsExtractor: CodeVisitor {
  public var options: [MesonOption] = []

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
    if node.functionName() != "option" { return }
    if !(node.argumentList is ArgumentList) { return }
    if let al = node.argumentList as? ArgumentList, let nameNode = al.getPositionalArg(idx: 0),
      let nameN = nameNode as? StringLiteral
    {
      let name = nameN.contents()
      if let type = al.getKwarg(name: "type") {
        if let sl = type as? StringLiteral {
          var description: String?
          if let descNode = al.getKwarg(name: "description") {
            if let descLiteral = descNode as? StringLiteral { description = descLiteral.contents() }
          }
          var deprecated = false
          if let kwarg = al.getKwarg(name: "deprecated"), let bool = kwarg as? BooleanLiteral {
            deprecated = bool.value
          }
          var comboVals: [String]?
          if let kwarg = al.getKwarg(name: "choices"), let arg = kwarg as? ArrayLiteral {
            comboVals = arg.args.filter { $0 is StringLiteral }.map {
              ($0 as! StringLiteral).contents()
            }
          }
          self.createOption(sl.contents(), name, description, deprecated, comboVals)
        }
      }
    }
  }

  private func createOption(
    _ type: String,
    _ name: String,
    _ description: String?,
    _ deprecated: Bool,
    _ comboVals: [String]? = nil
  ) {
    switch type {
    case "array": self.options.append(ArrayOption(name, description, deprecated, comboVals))
    case "boolean": self.options.append(BoolOption(name, description, deprecated))
    case "integer": self.options.append(IntOption(name, description, deprecated))
    case "string": self.options.append(StringOption(name, description, deprecated))
    case "combo": self.options.append(ComboOption(name, description, comboVals, deprecated))
    case "feature": self.options.append(FeatureOption(name, description, deprecated))
    default: _ = 1
    }
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
