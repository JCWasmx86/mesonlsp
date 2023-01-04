import SwiftTreeSitter

public func from_tree(file: MesonSourceFile, tree: SwiftTreeSitter.Node?) -> Node? {
  if let t = tree {
    if let type = t.nodeType {
      switch type {
      case "source_file":
        return SourceFile(file: file, node: t)
      case "statement":
        if t.namedChildCount != 1 {
          return nil
        }
        return from_tree(file: file, tree: t.namedChild(at: 0))
      case "jump_statement":
        return string_value(file: file, node: t) == "break"
          ? BreakNode(file: file, node: t) : ContinueNode(file: file, node: t)
      case "iteration_statement":
        return IterationStatement(file: file, node: t)
      case "selection_statement":
        return SelectionStatement(file: file, node: t)
      case "assignment_statement":
        return AssignmentStatement(file: file, node: t)
      case "function_expression":
        return FunctionExpression(file: file, node: t)
      case "argument_list":
        return ArgumentList(file: file, node: t)
      case "keyword_item":
        return KeywordItem(file: file, node: t)
      case "conditional_expression":
        return ConditionalExpression(file: file, node: t)
      case "unary_expression":
        return UnaryExpression(file: file, node: t)
      case "subscript_expression":
        return SubscriptExpression(file: file, node: t)
      case "expression":
        return from_tree(file: file, tree: t.namedChild(at: 0))
      case "condition":
        return from_tree(file: file, tree: t.namedChild(at: 0))
      case "function_id":
        return IdExpression(file: file, node: t)
      case "keyword_arg_key":
        return IdExpression(file: file, node: t)
      case "id_expression":
        return IdExpression(file: file, node: t)
      case "binary_expression":
        return BinaryExpression(file: file, node: t)
      case "string_literal":
        return StringLiteral(file: file, node: t)
      case "array_literal":
        return ArrayLiteral(file: file, node: t)
      case "method_expression":
        return MethodExpression(file: file, node: t)
      case "boolean_literal":
        return BooleanLiteral(file: file, node: t)
      case "primary_expression":
        return from_tree(file: file, tree: t.namedChild(at: 0))
      case "integer_literal":
        return IntegerLiteral(file: file, node: t)
      case "dictionary_literal":
        return DictionaryLiteral(file: file, node: t)
      case "key_value_item":
        return KeyValueItem(file: file, node: t)
      case "ERROR":
        return ErrorNode(file: file, node: t, msg: "Failed to parse")
      default:
        fatalError(type)
      }
    }
  }
  return nil
}
