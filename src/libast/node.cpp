#include "node.hpp"
#include "location.hpp"
#include <cstdint>
#include <cstring>
#include <format>
#include <memory>
#include <vector>

Node::Node(std::shared_ptr<SourceFile> file, TSNode node)
    : file(file), location(new Location(node)) {}

ArgumentList::ArgumentList(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(file, node) {
  for (uint32_t i = 0; i < ts_node_named_child_count(node); i++) {
    this->args.push_back(make_node(file, ts_node_named_child(node, i)));
  }
}

void ArgumentList::visitChildren(std::shared_ptr<CodeVisitor> visitor) {
  for (auto n : this->args)
    n->visit(visitor);
};

ArrayLiteral::ArrayLiteral(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(file, node) {
  for (uint32_t i = 0; i < ts_node_named_child_count(node); i++) {
    this->args.push_back(make_node(file, ts_node_named_child(node, i)));
  }
}

void ArrayLiteral::visitChildren(std::shared_ptr<CodeVisitor> visitor) {
  for (auto n : this->args)
    n->visit(visitor);
};

BuildDefinition::BuildDefinition(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(file, node) {
  for (uint32_t i = 0; i < ts_node_named_child_count(node); i++) {
    auto stmt = make_node(file, ts_node_named_child(node, i));
    if (stmt)
      this->stmts.push_back(stmt);
  }
}

void BuildDefinition::visitChildren(std::shared_ptr<CodeVisitor> visitor) {
  for (auto n : this->stmts)
    n->visit(visitor);
};

DictionaryLiteral::DictionaryLiteral(std::shared_ptr<SourceFile> file,
                                     TSNode node)
    : Node(file, node) {
  for (uint32_t i = 0; i < ts_node_named_child_count(node); i++) {
    this->values.push_back(make_node(file, ts_node_named_child(node, i)));
  }
}

void DictionaryLiteral::visitChildren(std::shared_ptr<CodeVisitor> visitor) {
  for (auto n : this->values)
    n->visit(visitor);
};

ConditionalExpression::ConditionalExpression(std::shared_ptr<SourceFile> file,
                                             TSNode node)
    : Node(file, node) {
  this->condition = make_node(file, ts_node_named_child(node, 0));
  this->ifTrue = make_node(file, ts_node_named_child(node, 1));
  this->ifFalse = make_node(file, ts_node_named_child(node, 2));
}

void ConditionalExpression::visitChildren(
    std::shared_ptr<CodeVisitor> visitor) {
  this->condition->visit(visitor);
  this->ifTrue->visit(visitor);
  this->ifFalse->visit(visitor);
};

SubscriptExpression::SubscriptExpression(std::shared_ptr<SourceFile> file,
                                         TSNode node)
    : Node(file, node) {
  this->outer = make_node(file, ts_node_named_child(node, 0));
  this->inner = make_node(file, ts_node_named_child(node, 1));
}

void SubscriptExpression::visitChildren(std::shared_ptr<CodeVisitor> visitor) {
  this->outer->visit(visitor);
  this->inner->visit(visitor);
};

MethodExpression::MethodExpression(std::shared_ptr<SourceFile> file,
                                   TSNode node)
    : Node(file, node) {
  this->obj = make_node(file, ts_node_named_child(node, 0));
  this->id = make_node(file, ts_node_named_child(node, 1));
  if (ts_node_named_child_count(node) != 2)
    this->args = make_node(file, ts_node_named_child(node, 2));
}

void MethodExpression::visitChildren(std::shared_ptr<CodeVisitor> visitor) {
  this->obj->visit(visitor);
  this->id->visit(visitor);
  if (this->args)
    this->args->visit(visitor);
};

FunctionExpression::FunctionExpression(std::shared_ptr<SourceFile> file,
                                       TSNode node)
    : Node(file, node) {
  this->id = make_node(file, ts_node_named_child(node, 0));
  if (ts_node_named_child_count(node) != 1)
    this->args = make_node(file, ts_node_named_child(node, 1));
}

void FunctionExpression::visitChildren(std::shared_ptr<CodeVisitor> visitor) {
  this->id->visit(visitor);
  if (this->args)
    this->args->visit(visitor);
};

KeyValueItem::KeyValueItem(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(file, node) {
  this->key = make_node(file, ts_node_named_child(node, 0));
  this->value = make_node(file, ts_node_named_child(node, 1));
}

void KeyValueItem::visitChildren(std::shared_ptr<CodeVisitor> visitor) {
  this->key->visit(visitor);
  this->value->visit(visitor);
};

KeywordItem::KeywordItem(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(file, node) {
  this->key = make_node(file, ts_node_named_child(node, 0));
  this->value = make_node(file, ts_node_named_child(node, 1));
}

void KeywordItem::visitChildren(std::shared_ptr<CodeVisitor> visitor) {
  this->key->visit(visitor);
  this->value->visit(visitor);
};

IterationStatement::IterationStatement(std::shared_ptr<SourceFile> file,
                                       TSNode node)
    : Node(file, node) {
  auto idList = ts_node_named_child(node, 0);
  for (uint32_t i = 0; i < ts_node_named_child_count(idList); i++) {
    this->ids.push_back(make_node(file, ts_node_named_child(idList, i)));
  }
  this->expression = make_node(file, ts_node_named_child(node, 1));
  for (uint32_t i = 2; i < ts_node_named_child_count(node); i++) {
    auto stmt = make_node(file, ts_node_named_child(node, i));
    this->stmts.push_back(stmt);
  }
}

void IterationStatement::visitChildren(std::shared_ptr<CodeVisitor> visitor) {
  for (auto id : this->ids)
    id->visit(visitor);
  this->expression->visit(visitor);
  for (auto stmt : this->stmts)
    stmt->visit(visitor);
}

AssignmentStatement::AssignmentStatement(std::shared_ptr<SourceFile> file,
                                         TSNode node)
    : Node(file, node) {
  this->lhs = make_node(file, ts_node_named_child(node, 0));
  auto op_str = file->extract_node_value(ts_node_named_child(node, 0));
  if (op_str == "=")
    this->op = AssignmentOperator::Equals;
  else if (op_str == "*=")
    this->op = AssignmentOperator::MulEquals;
  else if (op_str == "/=")
    this->op = AssignmentOperator::DivEquals;
  else if (op_str == "%=")
    this->op = AssignmentOperator::ModEquals;
  else if (op_str == "+=")
    this->op = AssignmentOperator::PlusEquals;
  else if (op_str == "-=")
    this->op = AssignmentOperator::MinusEquals;
  else
    this->op = AssignmentOpOther;
  this->rhs = make_node(file, ts_node_named_child(node, 2));
}

void AssignmentStatement::visitChildren(std::shared_ptr<CodeVisitor> visitor) {
  this->lhs->visit(visitor);
  this->rhs->visit(visitor);
}

BinaryExpression::BinaryExpression(std::shared_ptr<SourceFile> file,
                                   TSNode node)
    : Node(file, node) {
  this->lhs = make_node(file, ts_node_named_child(node, 0));
  auto ncc = ts_node_named_child_count(node);
  auto op_str = file->extract_node_value(
      (ncc == 2 ? ts_node_child : ts_node_named_child)(node, 1));
  if (op_str == "+")
    this->op = BinaryOperator::Plus;
  else if (op_str == "-")
    this->op = BinaryOperator::Minus;
  else if (op_str == "*")
    this->op = BinaryOperator::Mul;
  else if (op_str == "/")
    this->op = BinaryOperator::Div;
  else if (op_str == "%")
    this->op = BinaryOperator::Modulo;
  else if (op_str == "==")
    this->op = BinaryOperator::EqualsEquals;
  else if (op_str == "!=")
    this->op = BinaryOperator::NotEquals;
  else if (op_str == ">")
    this->op = BinaryOperator::Gt;
  else if (op_str == "<")
    this->op = BinaryOperator::Lt;
  else if (op_str == ">=")
    this->op = BinaryOperator::Ge;
  else if (op_str == "<=")
    this->op = BinaryOperator::Le;
  else if (op_str == "in")
    this->op = BinaryOperator::In;
  else if (op_str == "not in")
    this->op = BinaryOperator::NotIn;
  else if (op_str == "and")
    this->op = BinaryOperator::And;
  else if (op_str == "or")
    this->op = BinaryOperator::Or;
  else
    this->op = BinaryOperator::BinOpOther;
  this->rhs = make_node(file, ts_node_named_child(node, ncc == 2 ? 1 : 2));
}

void BinaryExpression::visitChildren(std::shared_ptr<CodeVisitor> visitor) {
  this->lhs->visit(visitor);
  this->rhs->visit(visitor);
}

UnaryExpression::UnaryExpression(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(file, node) {
  auto op_str = file->extract_node_value(ts_node_child(node, 0));
  if (op_str == "not")
    this->op = UnaryOperator::Not;
  else if (op_str == "!")
    this->op = UnaryOperator::ExclamationMark;
  else if (op_str == "-")
    this->op = UnaryOperator::UnaryMinus;
  else
    this->op = UnaryOther;
  this->expression = make_node(file, ts_node_named_child(node, 0));
}

void UnaryExpression::visitChildren(std::shared_ptr<CodeVisitor> visitor) {
  this->expression->visit(visitor);
}

StringLiteral::StringLiteral(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(file, node) {
  this->isFormat =
      strcmp(ts_node_type(ts_node_child(node, 0)), "string_format") == 0;
  this->id = file->extract_node_value(node);
}

void StringLiteral::visitChildren(std::shared_ptr<CodeVisitor> visitor) {}

IdExpression::IdExpression(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(file, node) {
  this->id = file->extract_node_value(node);
}

void IdExpression::visitChildren(std::shared_ptr<CodeVisitor> visitor) {}

BooleanLiteral::BooleanLiteral(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(file, node) {
  this->value = file->extract_node_value(node) == "true";
}

void BooleanLiteral::visitChildren(std::shared_ptr<CodeVisitor> visitor) {}

IntegerLiteral::IntegerLiteral(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(file, node) {
  this->value = file->extract_node_value(node);
}

void IntegerLiteral::visitChildren(std::shared_ptr<CodeVisitor> visitor) {}

ContinueNode::ContinueNode(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(file, node) {}

void ContinueNode::visitChildren(std::shared_ptr<CodeVisitor> visitor) {}

BreakNode::BreakNode(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(file, node) {}

void BreakNode::visitChildren(std::shared_ptr<CodeVisitor> visitor) {}

SelectionStatement::SelectionStatement(std::shared_ptr<SourceFile> file,
                                       TSNode node)
    : Node(file, node) {
  auto child_count = ts_node_child_count(node);
  uint32_t idx = 0;
  std::shared_ptr<Node> sI = nullptr;
  std::vector<std::shared_ptr<Node>> tmp;
  std::vector<std::shared_ptr<Node>> cs;
  std::vector<std::vector<std::shared_ptr<Node>>> bb;
  while (idx < child_count) {
    auto c = ts_node_child(node, idx);
    auto sv = file->extract_node_value(c);
    auto node_type = ts_node_type(c);
    if ((sv == "if" || strcmp(node_type, "if") == 0) && !sI) {
      while (file->extract_node_value(ts_node_child(node, idx + 1)) ==
             "comment")
        idx++;
      sI = make_node(file, ts_node_child(node, idx + 1));
      idx += 1;
    } else if (sv == "elif") {
      bb.push_back(tmp);
      while (file->extract_node_value(ts_node_child(node, idx + 1)) ==
             "comment")
        idx++;
      tmp = {};
      cs.push_back(make_node(file, ts_node_child(node, idx + 1)));
      idx++;
    } else if (sv == "else") {
      bb.push_back(tmp);
      tmp = {};
    } else if (sv != "comment" && ts_node_named_child_count(c) == 1) {
      auto c_child_type = ts_node_type(ts_node_named_child(c, 0));
      if (strcmp(c_child_type, "comment") != 0)
        tmp.push_back(make_node(file, c));
    }
    idx++;
  }
}

void SelectionStatement::visitChildren(std::shared_ptr<CodeVisitor> visitor) {
  for (auto condition : this->conditions)
    condition->visit(visitor);
  for (auto b : this->blocks)
    for (auto bb : b)
      bb->visit(visitor);
}

void ErrorNode::visitChildren(std::shared_ptr<CodeVisitor> visitor) {}
void ErrorNode::visit(std::shared_ptr<CodeVisitor> visitor) {
  visitor->visitErrorNode(this);
}
void ContinueNode::visit(std::shared_ptr<CodeVisitor> visitor) {
  visitor->visitContinueNode(this);
}
void BreakNode::visit(std::shared_ptr<CodeVisitor> visitor) {
  visitor->visitBreakNode(this);
}
void ArgumentList::visit(std::shared_ptr<CodeVisitor> visitor) {
  visitor->visitArgumentList(this);
}
void ArrayLiteral::visit(std::shared_ptr<CodeVisitor> visitor) {
  visitor->visitArrayLiteral(this);
}
void AssignmentStatement::visit(std::shared_ptr<CodeVisitor> visitor) {
  visitor->visitAssignmentStatement(this);
}
void BinaryExpression::visit(std::shared_ptr<CodeVisitor> visitor) {
  visitor->visitBinaryExpression(this);
}
void BooleanLiteral::visit(std::shared_ptr<CodeVisitor> visitor) {
  visitor->visitBooleanLiteral(this);
}
void BuildDefinition::visit(std::shared_ptr<CodeVisitor> visitor) {
  visitor->visitBuildDefinition(this);
}
void ConditionalExpression::visit(std::shared_ptr<CodeVisitor> visitor) {
  visitor->visitConditionalExpression(this);
}
void DictionaryLiteral::visit(std::shared_ptr<CodeVisitor> visitor) {
  visitor->visitDictionaryLiteral(this);
}
void FunctionExpression::visit(std::shared_ptr<CodeVisitor> visitor) {
  visitor->visitFunctionExpression(this);
}
void IdExpression::visit(std::shared_ptr<CodeVisitor> visitor) {
  visitor->visitIdExpression(this);
}
void IntegerLiteral::visit(std::shared_ptr<CodeVisitor> visitor) {
  visitor->visitIntegerLiteral(this);
}
void IterationStatement::visit(std::shared_ptr<CodeVisitor> visitor) {
  visitor->visitIterationStatement(this);
}
void KeyValueItem::visit(std::shared_ptr<CodeVisitor> visitor) {
  visitor->visitKeyValueItem(this);
}
void KeywordItem::visit(std::shared_ptr<CodeVisitor> visitor) {
  visitor->visitKeywordItem(this);
}
void MethodExpression::visit(std::shared_ptr<CodeVisitor> visitor) {
  visitor->visitMethodExpression(this);
}
void SelectionStatement::visit(std::shared_ptr<CodeVisitor> visitor) {
  visitor->visitSelectionStatement(this);
}
void StringLiteral::visit(std::shared_ptr<CodeVisitor> visitor) {
  visitor->visitStringLiteral(this);
}
void SubscriptExpression::visit(std::shared_ptr<CodeVisitor> visitor) {
  visitor->visitSubscriptExpression(this);
}
void UnaryExpression::visit(std::shared_ptr<CodeVisitor> visitor) {
  visitor->visitUnaryExpression(this);
}

std::shared_ptr<Node> make_node(std::shared_ptr<SourceFile> file, TSNode node) {
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
  if (strcmp(node_type, "id_expression") == 0 ||
      strcmp(node_type, "function_id") == 0 ||
      strcmp(node_type, "keyword_arg_key") == 0)
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
  if (strcmp(node_type, "source_file") == 0)
    return std::make_shared<BuildDefinition>(file,
                                             ts_node_named_child(node, 0));
  if (strcmp(node_type, "statement") == 0 &&
      ts_node_named_child_count(node) == 1)
    return make_node(file, ts_node_named_child(node, 0));
  if (strcmp(node_type, "expression") == 0 &&
      ts_node_named_child_count(node) == 1)
    return make_node(file, ts_node_named_child(node, 0));
  if (strcmp(node_type, "condition") == 0 &&
      ts_node_named_child_count(node) == 1)
    return make_node(file, ts_node_named_child(node, 0));
  if (strcmp(node_type, "primary_expression") == 0 &&
      ts_node_named_child_count(node) == 1)
    return make_node(file, ts_node_named_child(node, 0));
  if (strcmp(node_type, "statement") == 0 &&
      ts_node_named_child_count(node) == 1)
    return make_node(file, ts_node_named_child(node, 0));
  if (strcmp(node_type, "statement") == 0 &&
      ts_node_named_child_count(node) == 0)
    return nullptr;
  if (strcmp(node_type, "jump_statement") == 0) {
    auto content = file->extract_node_value(node);
    if (content == "break")
      return std::make_shared<BreakNode>(file, node);
    if (content == "continue")
      return std::make_shared<ContinueNode>(file, node);
  }
  return std::make_shared<ErrorNode>(
      file, node, std::format("Unknown node_type '{}'", node_type));
}
