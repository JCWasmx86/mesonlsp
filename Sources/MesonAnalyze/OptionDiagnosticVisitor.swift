import Logging
import MesonAST

class OptionDiagnosticVisitor: CodeVisitor {
  private static let LOG = Logger(label: "MesonAnalyze::OptionDiagnosticVisitor")
  private let metadata: MesonMetadata

  init(_ metadata: MesonMetadata) { self.metadata = metadata }

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

  private func checkName(_ sl: StringLiteral) {
    let contents = sl.contents()
    for c in contents {
      let alpha = c.isLetter || c.isNumber
      if !alpha && c != "_" && c != "-" {
        self.metadata.registerDiagnostic(
          node: sl,
          diag: MesonDiagnostic(
            sev: .error,
            node: sl,
            message: "Invalid chars in name: Expected `a-z`, `A-Z`, `0-9`, `-` or `_`"
          )
        )
        return
      }
    }
  }

  private func isInteger(_ dv: Node?) -> Bool {
    guard let dv = dv else { return false }
    if dv is IntegerLiteral {
      return true
    } else if let unaryExpr = dv as? UnaryExpression, let unOp = unaryExpr.op, unOp == .minus,
      unaryExpr.expression is IntegerLiteral
    {
      return true
    }
    return false
  }

  private func extractInteger(_ dv: Node?) -> Int? {
    guard let dv = dv else { return nil }
    if let dvi = dv as? IntegerLiteral {
      return dvi.parse()
    } else if let unaryExpr = dv as? UnaryExpression, let unOp = unaryExpr.op, unOp == .minus,
      let dvi = unaryExpr.expression as? IntegerLiteral
    {
      return -dvi.parse()
    }
    return nil
  }

  // Refactor this!
  // swiftlint:disable cyclomatic_complexity
  public func visitFunctionExpression(node: FunctionExpression) {
    self.metadata.registerFunctionCall(call: node)
    node.visitChildren(visitor: self)
    guard let idExpr = node.id as? IdExpression else { return }
    if idExpr.id != "option" {
      self.metadata.registerDiagnostic(
        node: node,
        diag: MesonDiagnostic(
          sev: .error,
          node: node,
          message: "Invalid function name in meson options file: \(idExpr.id)"
        )
      )
      return
    }
    guard let al = node.argumentList as? ArgumentList else {
      self.metadata.registerDiagnostic(
        node: node,
        diag: MesonDiagnostic(
          sev: .error,
          node: node,
          message: "Missing arguments in call to `option`"
        )
      )
      return
    }
    guard let nameNode = al.getPositionalArg(idx: 0) else {
      self.metadata.registerDiagnostic(
        node: node,
        diag: MesonDiagnostic(sev: .error, node: node, message: "Missing option name")
      )
      return
    }
    guard let nameNodeSl = nameNode as? StringLiteral else {
      self.metadata.registerDiagnostic(
        node: nameNode,
        diag: MesonDiagnostic(sev: .error, node: nameNode, message: "Expected string literal!")
      )
      return
    }
    Self.LOG.info("Found option: \(nameNodeSl.contents())")
    self.checkName(nameNodeSl)

    guard let optionType = al.getKwarg(name: "type") else {
      self.metadata.registerDiagnostic(
        node: nameNode,
        diag: MesonDiagnostic(sev: .error, node: nameNode, message: "Missing option type")
      )
      return
    }
    guard let optionTypeSL = optionType as? StringLiteral else {
      self.metadata.registerDiagnostic(
        node: optionType,
        diag: MesonDiagnostic(
          sev: .error,
          node: optionType,
          message: "Expected option type to be a string literal"
        )
      )
      return
    }
    let defaultValue = al.getKwarg(name: "value")
    switch optionTypeSL.contents() {
    case "string":
      if let dv = defaultValue {
        if !(dv is StringLiteral) {
          self.metadata.registerDiagnostic(
            node: dv,
            diag: MesonDiagnostic(sev: .error, node: dv, message: "Expected string literal")
          )
        }
      }
    case "integer":
      var parsed: Int?
      if let dv = defaultValue {
        if let dvi = dv as? IntegerLiteral {
          parsed = dvi.parse()
        } else if let unaryExpr = dv as? UnaryExpression, let unOp = unaryExpr.op, unOp == .minus,
          let dvi = unaryExpr.expression as? IntegerLiteral
        {
          parsed = -dvi.parse()
        } else {
          self.metadata.registerDiagnostic(
            node: dv,
            diag: MesonDiagnostic(sev: .error, node: dv, message: "Expected integer literal")
          )
        }
      }
      let minNode = al.getKwarg(name: "min")
      let maxNode = al.getKwarg(name: "max")
      if minNode != nil {
        if !isInteger(minNode) {
          self.metadata.registerDiagnostic(
            node: minNode!,
            diag: MesonDiagnostic(sev: .error, node: minNode!, message: "Expected integer literal")
          )
        }
      }
      if maxNode != nil {
        if !isInteger(maxNode) {
          self.metadata.registerDiagnostic(
            node: maxNode!,
            diag: MesonDiagnostic(sev: .error, node: maxNode!, message: "Expected integer literal")
          )
        }
      }
      if let minV = self.extractInteger(minNode), let maxV = self.extractInteger(maxNode) {
        if parsed != nil {
          if parsed! < minV {
            self.metadata.registerDiagnostic(
              node: defaultValue!,
              diag: MesonDiagnostic(
                sev: .warning,
                node: defaultValue!,
                message: "Default value (\(parsed!)) is less than the minimum value (\(minV))"
              )
            )
          } else if parsed! > maxV {
            self.metadata.registerDiagnostic(
              node: defaultValue!,
              diag: MesonDiagnostic(
                sev: .warning,
                node: defaultValue!,
                message: "Default value (\(parsed!)) is more than the maximum value (\(maxV))"
              )
            )
          }
        }
        if maxV < minV {
          self.metadata.registerDiagnostic(
            node: maxNode!,
            diag: MesonDiagnostic(
              sev: .warning,
              node: maxNode!,
              message: "Maximum value is less than the minimum value"
            )
          )
        }
      } else if let minV = self.extractInteger(minNode) {
        if parsed != nil {
          if parsed! < minV {
            self.metadata.registerDiagnostic(
              node: defaultValue!,
              diag: MesonDiagnostic(
                sev: .warning,
                node: defaultValue!,
                message: "Default value (\(parsed!)) is less than the minimum value (\(minV))"
              )
            )
          }
        }
      } else if let maxV = self.extractInteger(maxNode) {
        if parsed != nil {
          if parsed! > maxV {
            self.metadata.registerDiagnostic(
              node: defaultValue!,
              diag: MesonDiagnostic(
                sev: .warning,
                node: defaultValue!,
                message: "Default value (\(parsed!)) is more than the maximum value (\(maxV))"
              )
            )
          }
        }
      }
    case "boolean":
      if let dv = defaultValue {
        if !(dv is StringLiteral || dv is BooleanLiteral) {
          self.metadata.registerDiagnostic(
            node: dv,
            diag: MesonDiagnostic(
              sev: .error,
              node: dv,
              message: "Expected boolean or string literal"
            )
          )
        } else if dv is StringLiteral {
          let contents = (dv as! StringLiteral).contents()
          if contents == "true" || contents == "false" {
            self.metadata.registerDiagnostic(
              node: dv,
              diag: MesonDiagnostic(
                sev: .warning,
                node: dv,
                message: "String literals as value for boolean options are deprecated"
              )
            )
          } else {
            self.metadata.registerDiagnostic(
              node: dv,
              diag: MesonDiagnostic(
                sev: .warning,
                node: dv,
                message: "Boolean options must have boolean values"
              )
            )
          }
        }
      }
    case "combo":
      var parsed: String?
      if let dv = defaultValue {
        if !(dv is StringLiteral) {
          self.metadata.registerDiagnostic(
            node: dv,
            diag: MesonDiagnostic(sev: .error, node: dv, message: "Expected string literal")
          )
        } else {
          parsed = (dv as! StringLiteral).contents()
        }
      }
      var setChoices: [String] = []
      if let choices = al.getKwarg(name: "choices") {
        if let arr = choices as? ArrayLiteral {
          for val in arr.args {
            if let sl = val as? StringLiteral {
              let contents = sl.contents()
              if setChoices.contains(contents) {
                self.metadata.registerDiagnostic(
                  node: val,
                  diag: MesonDiagnostic(
                    sev: .error,
                    node: val,
                    message: "Duplicate choice: '\(contents)'"
                  )
                )
              }
              setChoices.append(contents)
            } else {
              self.metadata.registerDiagnostic(
                node: val,
                diag: MesonDiagnostic(sev: .error, node: val, message: "Expected string")
              )
            }
          }
          if setChoices.isEmpty {
            self.metadata.registerDiagnostic(
              node: arr,
              diag: MesonDiagnostic(sev: .error, node: arr, message: "Expected at least one choice")
            )
          }
        } else {
          self.metadata.registerDiagnostic(
            node: choices,
            diag: MesonDiagnostic(sev: .error, node: choices, message: "Expected a list of strings")
          )
        }
      } else {
        self.metadata.registerDiagnostic(
          node: node,
          diag: MesonDiagnostic(
            sev: .error,
            node: node,
            message: "Missing keyword 'choices' for combo-option"
          )
        )
      }
      if let s = parsed {
        if !setChoices.contains(s) {
          self.metadata.registerDiagnostic(
            node: defaultValue!,
            diag: MesonDiagnostic(
              sev: .warning,
              node: defaultValue!,
              message: "Default value ('\(s)') is not in the set of choices: \(setChoices)"
            )
          )
        }
      }
    case "array":
      var values: [String] = []
      if defaultValue != nil {
        if let arr = defaultValue as? ArrayLiteral {
          for val in arr.args {
            if let sl = val as? StringLiteral {
              let contents = sl.contents()
              if values.contains(contents) {
                self.metadata.registerDiagnostic(
                  node: val,
                  diag: MesonDiagnostic(
                    sev: .error,
                    node: val,
                    message: "Duplicate value: '\(contents)'"
                  )
                )
              }
              values.append(contents)
            } else {
              self.metadata.registerDiagnostic(
                node: val,
                diag: MesonDiagnostic(sev: .error, node: val, message: "Expected string")
              )
            }
          }
        } else {
          self.metadata.registerDiagnostic(
            node: defaultValue!,
            diag: MesonDiagnostic(
              sev: .error,
              node: defaultValue!,
              message: "Expected a list of strings"
            )
          )
        }
      }
      var choicesArr: [String] = []
      if let choices = al.getKwarg(name: "choices") {
        if let arr = choices as? ArrayLiteral {
          for val in arr.args {
            if let sl = val as? StringLiteral {
              let contents = sl.contents()
              if choicesArr.contains(contents) {
                self.metadata.registerDiagnostic(
                  node: val,
                  diag: MesonDiagnostic(
                    sev: .error,
                    node: val,
                    message: "Duplicate choice: '\(contents)'"
                  )
                )
              }
              choicesArr.append(contents)
            } else {
              self.metadata.registerDiagnostic(
                node: val,
                diag: MesonDiagnostic(sev: .error, node: val, message: "Expected string")
              )
            }
          }
        } else {
          self.metadata.registerDiagnostic(
            node: choices,
            diag: MesonDiagnostic(sev: .error, node: choices, message: "Expected a list of strings")
          )
        }
      }
    // We should check the choicesArr against the other valueArr.
    case "feature":
      if let dv = defaultValue {
        if let sl = defaultValue as? StringLiteral {
          let contents = sl.contents()
          if contents != "enabled" && contents != "disabled" && contents != "auto" {
            self.metadata.registerDiagnostic(
              node: dv,
              diag: MesonDiagnostic(
                sev: .error,
                node: dv,
                message: "Expected one of: 'enabled', 'disabled', 'auto'"
              )
            )
          }
        }
      }
    default:
      self.metadata.registerDiagnostic(
        node: optionType,
        diag: MesonDiagnostic(
          sev: .error,
          node: optionType,
          message: "Unknown option type: '\(optionTypeSL.contents())'"
        )
      )

    }
  }
  // swiftlint:enable cyclomatic_complexity

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

  public func visitStringLiteral(node: StringLiteral) {
    self.metadata.registerStringLiteral(node: node)
    node.visitChildren(visitor: self)
  }

  public func visitArrayLiteral(node: ArrayLiteral) { node.visitChildren(visitor: self) }

  public func visitBooleanLiteral(node: BooleanLiteral) { node.visitChildren(visitor: self) }

  public func visitIntegerLiteral(node: IntegerLiteral) { node.visitChildren(visitor: self) }

  public func visitDictionaryLiteral(node: DictionaryLiteral) { node.visitChildren(visitor: self) }

  public func visitKeyValueItem(node: KeyValueItem) { node.visitChildren(visitor: self) }
}
