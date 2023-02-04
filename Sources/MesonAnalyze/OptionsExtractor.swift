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
    let al = (node.argumentList as! ArgumentList)
    if let nameNode = al.getPositionalArg(idx: 0) {
      if let nameN = nameNode as? StringLiteral {
        let name = nameN.contents()
        if let type = al.getKwarg(name: "type") {
          if let sl = type as? StringLiteral {
            var description: String?
            if let descNode = al.getKwarg(name: "description") {
              if let descLiteral = descNode as? StringLiteral {
                description = descLiteral.contents()
              }
            }
            switch sl.contents() {
            case "array": self.options.append(ArrayOption(name, description))
            case "boolean": self.options.append(BoolOption(name, description))
            case "int": self.options.append(IntOption(name, description))
            case "string": self.options.append(StringOption(name, description))
            case "combo": self.options.append(ComboOption(name, description))
            case "feature": self.options.append(FeatureOption(name, description))
            default: _ = 1
            }
          }
        }
      }
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
