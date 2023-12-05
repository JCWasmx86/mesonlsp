#include "node.hpp"
#include "location.hpp"
#include <cstring>
#include <format>
#include <memory>

Node::Node(std::shared_ptr<MesonSourceFile> file, TSNode node)
    : file(file), location(new Location(node)) {}

ArgumentList::ArgumentList(std::shared_ptr<MesonSourceFile> file, TSNode node)
    : Node(file, node) {
  for (uint32_t i = 0; i < ts_node_named_child_count(node); i++) {
    this->args.push_back(make_node(file, ts_node_named_child(node, i)));
  }
}

ArrayLiteral::ArrayLiteral(std::shared_ptr<MesonSourceFile> file, TSNode node)
    : Node(file, node) {
  for (uint32_t i = 0; i < ts_node_named_child_count(node); i++) {
    this->args.push_back(make_node(file, ts_node_named_child(node, i)));
  }
}

std::shared_ptr<Node> make_node(std::shared_ptr<MesonSourceFile> file,
                                TSNode node) {
  auto node_type = ts_node_type(node);
  if (strcmp(node_type, "argument_list") == 0)
    return std::make_shared<ArgumentList>(file, node);
  if (strcmp(node_type, "array_literal") == 0)
    return std::make_shared<ArrayLiteral>(file, node);
  if (strcmp(node_type, "assignment_statement") == 0)
    return std::make_shared<AssignmentStatement>(file, node);
  if (strcmp(node_type, "binary_expression") == 0)
    return std::make_shared<BinaryExpression>(file, node);
  if (strcmp(node_type, "boolean_literal") == 0)
    return std::make_shared<BooleanLiteral>(file, node);
  if (strcmp(node_type, "build_definition") == 0)
    return std::make_shared<BuildDefinition>(file, node);
  if (strcmp(node_type, "dictionary_literal") == 0)
    return std::make_shared<DictionaryLiteral>(file, node);
  if (strcmp(node_type, "function_expression") == 0)
    return std::make_shared<FunctionExpression>(file, node);
  if (strcmp(node_type, "id_expression") == 0)
    return std::make_shared<IdExpression>(file, node);
  if (strcmp(node_type, "integer_literal") == 0)
    return std::make_shared<IntegerLiteral>(file, node);
  if (strcmp(node_type, "iteration_statement") == 0)
    return std::make_shared<IterationStatement>(file, node);
  if (strcmp(node_type, "key_value_item") == 0)
    return std::make_shared<KeyValueItem>(file, node);
  if (strcmp(node_type, "keyword_item") == 0)
    return std::make_shared<KeywordItem>(file, node);
  if (strcmp(node_type, "method_expression") == 0)
    return std::make_shared<MethodExpression>(file, node);
  if (strcmp(node_type, "selection_statement") == 0)
    return std::make_shared<SelectionStatement>(file, node);
  if (strcmp(node_type, "string_literal") == 0)
    return std::make_shared<StringLiteral>(file, node);
  if (strcmp(node_type, "subscript_expression") == 0)
    return std::make_shared<SubscriptExpression>(file, node);
  if (strcmp(node_type, "unary_expression") == 0)
    return std::make_shared<UnaryExpression>(file, node);
  if (strcmp(node_type, "conditional_expression") == 0)
    return std::make_shared<ConditionalExpression>(file, node);
  // TODO: jump_statement == break/continue
  // TODO: ERROR, expression, condition, function_id,
  // TODO: keyword_arg_key, primary_expression
  return std::make_shared<ErrorNode>(
      file, node, std::format("Unknown node_type '{}'", node_type));
}