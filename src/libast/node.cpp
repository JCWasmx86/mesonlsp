#include "node.hpp"

#include "location.hpp"
#include "sourcefile.hpp"

#include <cctype>
#include <cstdint>
#include <cstring>
#include <format>
#include <memory>
#include <optional>
#include <regex>
#include <set>
#include <string>
#include <tree_sitter/api.h>
#include <utility>
#include <vector>

const static std::regex
    FORMAT_STRING_REGEX("@([a-zA-Z_][a-zA-Z_\\d]*)@");               // NOLINT
const static std::regex STR_FORMAT_REGEX("@(\\d+)@");                // NOLINT
const std::string INVALID_FUNCTION_NAME_STR = INVALID_FUNCTION_NAME; // NOLINT
const std::string INVALID_KEY_NAME_STR = INVALID_KEY_NAME;           // NOLINT

// NOLINTBEGIN
enum {
  anon_sym_if = 1,
  anon_sym_elif = 2,
  anon_sym_else = 3,
  anon_sym_endif = 4,
  anon_sym_foreach = 5,
  anon_sym_COLON = 6,
  anon_sym_endforeach = 7,
  anon_sym_EQ = 8,
  anon_sym_STAR_EQ = 9,
  anon_sym_SLASH_EQ = 10,
  anon_sym_PERCENT_EQ = 11,
  anon_sym_PLUS_EQ = 12,
  anon_sym_DASH_EQ = 13,
  anon_sym_break = 14,
  anon_sym_continue = 15,
  anon_sym_LPAREN = 16,
  anon_sym_RPAREN = 17,
  anon_sym_COMMA = 18,
  anon_sym_DOT = 19,
  anon_sym_LBRACK = 20,
  anon_sym_RBRACK = 21,
  anon_sym_not = 22,
  anon_sym_BANG = 23,
  anon_sym_DASH = 24,
  anon_sym_and = 25,
  anon_sym_or = 26,
  anon_sym_PLUS = 27,
  anon_sym_STAR = 28,
  anon_sym_SLASH = 29,
  anon_sym_PERCENT = 30,
  anon_sym_EQ_EQ = 31,
  anon_sym_BANG_EQ = 32,
  anon_sym_GT = 33,
  anon_sym_LT = 34,
  anon_sym_GT_EQ = 35,
  anon_sym_LT_EQ = 36,
  anon_sym_in = 37,
  anon_sym_QMARK = 38,
  sym__DECIMAL_NUMBER = 39,
  anon_sym_0o = 40,
  anon_sym_0O = 41,
  sym__OCTAL_NUMBER = 42,
  anon_sym_0x = 43,
  anon_sym_0X = 44,
  sym__HEX_NUMBER = 45,
  anon_sym_0b = 46,
  anon_sym_0B = 47,
  sym__BINARY_NUMBER = 48,
  sym_escape_sequence = 49,
  anon_sym_SQUOTE = 50,
  aux_sym_string_simple_token1 = 51,
  anon_sym_f_SQUOTE = 52,
  anon_sym_f_SQUOTE_SQUOTE_SQUOTE = 53,
  aux_sym_string_format_multiline_token1 = 54,
  anon_sym_SQUOTE_SQUOTE = 55,
  anon_sym_SQUOTE_SQUOTE_SQUOTE = 56,
  anon_sym_true = 57,
  anon_sym_false = 58,
  anon_sym_LF = 59,
  anon_sym_CR_LF = 60,
  anon_sym_LBRACE = 61,
  anon_sym_RBRACE = 62,
  sym__IDENTIFIER = 63,
  sym__comment = 64,
  sym_source_file = 65,
  sym_build_definition = 66,
  sym_statement = 67,
  sym__statement_without = 68,
  sym_selection_statement = 69,
  sym_iteration_statement = 70,
  sym_assignment_statement = 71,
  sym_assignment_operator = 72,
  sym_jump_statement = 73,
  sym_condition = 74,
  sym_expression = 75,
  sym_function_expression = 76,
  sym_argument_list = 77,
  sym_keyword_item = 78,
  sym_key_value_item = 79,
  sym_method_expression = 80,
  sym_subscript_expression = 81,
  sym_unary_expression = 82,
  sym_binary_expression = 83,
  sym_add_operator = 84,
  sym_mult_operator = 85,
  sym_equ_operator = 86,
  sym_rel_operator = 87,
  sym_conditional_expression = 88,
  sym__literal = 89,
  sym_integer_literal = 90,
  sym__decimal_literal = 91,
  sym__octal_literal = 92,
  sym__hex_literal = 93,
  sym__binary_literal = 94,
  sym_string_literal = 95,
  sym_string_simple = 96,
  sym_string_format = 97,
  sym_string_format_simple = 98,
  sym_string_format_multiline = 99,
  sym_string_multiline = 100,
  sym_boolean_literal = 101,
  sym_array_literal = 102,
  sym__NEWLINE = 103,
  sym_dictionary_literal = 104,
  sym_identifier_list = 105,
  sym_primary_expression = 106,
  sym_function_id = 107,
  sym_keyword_arg_key = 108,
  sym_id_expression = 109,
  aux_sym_build_definition_repeat1 = 110,
  aux_sym_selection_statement_repeat1 = 111,
  aux_sym_selection_statement_repeat2 = 112,
  aux_sym_argument_list_repeat1 = 113,
  aux_sym_key_value_list_repeat1 = 114,
  aux_sym_string_simple_repeat1 = 115,
  aux_sym_string_format_multiline_repeat1 = 116,
  aux_sym_array_literal_repeat1 = 117,
  aux_sym_identifier_list_repeat1 = 118,
};

// NOLINTEND

Node::Node(std::shared_ptr<SourceFile> file, TSNode node)
    : file(std::move(file)), location(node) {}

ArgumentList::ArgumentList(const std::shared_ptr<SourceFile> &file, TSNode node)
    : Node(file, node) {
  for (uint32_t i = 0; i < ts_node_named_child_count(node); i++) {
    this->args.push_back(makeNode(file, ts_node_named_child(node, i)));
  }
}

void ArgumentList::visitChildren(CodeVisitor *visitor) {
  for (const auto &arg : this->args) {
    arg->visit(visitor);
  }
};

void ArgumentList::setParents() {
  for (const auto &arg : this->args) {
    arg->parent = this;
    arg->setParents();
  }
}

ArrayLiteral::ArrayLiteral(const std::shared_ptr<SourceFile> &file, TSNode node)
    : Node(file, node) {
  for (uint32_t i = 0; i < ts_node_named_child_count(node); i++) {
    auto child = ts_node_named_child(node, i);
    this->args.push_back(makeNode(file, child));
  }
}

void ArrayLiteral::visitChildren(CodeVisitor *visitor) {
  for (const auto &element : this->args) {
    element->visit(visitor);
  }
};

void ArrayLiteral::setParents() {
  for (const auto &element : this->args) {
    element->parent = this;
    element->setParents();
  }
}

BuildDefinition::BuildDefinition(const std::shared_ptr<SourceFile> &file,
                                 TSNode node)
    : Node(file, node) {
  if (!node.id) {
    return;
  }
  for (uint32_t i = 0; i < ts_node_named_child_count(node); i++) {
    auto stmt = makeNode(file, ts_node_named_child(node, i));
    if (stmt) {
      this->stmts.push_back(stmt);
    }
  }
}

void BuildDefinition::setParents() {
  for (const auto &stmt : this->stmts) {
    stmt->parent = this;
    stmt->setParents();
  }
}

void BuildDefinition::visitChildren(CodeVisitor *visitor) {
  for (const auto &stmt : this->stmts) {
    stmt->visit(visitor);
  }
};

DictionaryLiteral::DictionaryLiteral(const std::shared_ptr<SourceFile> &file,
                                     TSNode node)
    : Node(file, node) {
  for (uint32_t i = 0; i < ts_node_named_child_count(node); i++) {
    this->values.push_back(makeNode(file, ts_node_named_child(node, i)));
  }
}

void DictionaryLiteral::setParents() {
  for (const auto &item : this->values) {
    item->parent = this;
    item->setParents();
  }
}

void DictionaryLiteral::visitChildren(CodeVisitor *visitor) {
  for (const auto &item : this->values) {
    item->visit(visitor);
  }
};

ConditionalExpression::ConditionalExpression(
    const std::shared_ptr<SourceFile> &file, TSNode node)
    : Node(file, node) {
  this->condition = makeNode(file, ts_node_named_child(node, 0));
  this->ifTrue = makeNode(file, ts_node_named_child(node, 1));
  this->ifFalse = makeNode(file, ts_node_named_child(node, 2));
}

void ConditionalExpression::setParents() {
  this->condition->parent = this;
  this->ifFalse->parent = this;
  this->ifTrue->parent = this;
  this->condition->setParents();
  this->ifFalse->setParents();
  this->ifTrue->setParents();
}

void ConditionalExpression::visitChildren(CodeVisitor *visitor) {
  this->condition->visit(visitor);
  this->ifTrue->visit(visitor);
  this->ifFalse->visit(visitor);
};

SubscriptExpression::SubscriptExpression(
    const std::shared_ptr<SourceFile> &file, TSNode node)
    : Node(file, node) {
  this->outer = makeNode(file, ts_node_named_child(node, 0));
  this->inner = makeNode(file, ts_node_named_child(node, 1));
}

void SubscriptExpression::setParents() {
  this->outer->parent = this;
  this->inner->parent = this;
  this->outer->setParents();
  this->inner->setParents();
}

void SubscriptExpression::visitChildren(CodeVisitor *visitor) {
  this->outer->visit(visitor);
  this->inner->visit(visitor);
};

MethodExpression::MethodExpression(const std::shared_ptr<SourceFile> &file,
                                   TSNode node)
    : Node(file, node) {
  this->obj = makeNode(file, ts_node_named_child(node, 0));
  this->id = makeNode(file, ts_node_named_child(node, 1));
  if (ts_node_named_child_count(node) != 2) {
    this->args = makeNode(file, ts_node_named_child(node, 2));
  }
}

void MethodExpression::visitChildren(CodeVisitor *visitor) {
  this->obj->visit(visitor);
  this->id->visit(visitor);
  if (this->args) {
    this->args->visit(visitor);
  }
};

void MethodExpression::setParents() {
  this->obj->parent = this;
  this->id->parent = this;
  if (this->args) {
    this->args->parent = this;
  }
  this->obj->setParents();
  this->id->setParents();
  if (this->args) {
    this->args->setParents();
  }
}

FunctionExpression::FunctionExpression(const std::shared_ptr<SourceFile> &file,
                                       TSNode node)
    : Node(file, node) {
  this->id = makeNode(file, ts_node_named_child(node, 0));
  if (ts_node_named_child_count(node) != 1) {
    this->args = makeNode(file, ts_node_named_child(node, 1));
  }
}

void FunctionExpression::setParents() {
  this->id->parent = this;
  if (this->args) {
    this->args->parent = this;
  }
  this->id->setParents();
  if (this->args) {
    this->args->setParents();
  }
}

void FunctionExpression::visitChildren(CodeVisitor *visitor) {
  this->id->visit(visitor);
  if (this->args) {
    this->args->visit(visitor);
  }
};

KeyValueItem::KeyValueItem(const std::shared_ptr<SourceFile> &file, TSNode node)
    : Node(file, node) {
  this->key = makeNode(file, ts_node_named_child(node, 0));
  this->value = makeNode(file, ts_node_named_child(node, 1));
}

void KeyValueItem::setParents() {
  this->key->parent = this;
  this->value->parent = this;
  this->key->setParents();
  this->value->setParents();
}

void KeyValueItem::visitChildren(CodeVisitor *visitor) {
  this->key->visit(visitor);
  this->value->visit(visitor);
};

KeywordItem::KeywordItem(const std::shared_ptr<SourceFile> &file, TSNode node)
    : Node(file, node) {
  this->key = makeNode(file, ts_node_named_child(node, 0));
  this->value = makeNode(file, ts_node_named_child(node, 1));
  auto *casted = dynamic_cast<IdExpression *>(this->key.get());
  if (casted == nullptr) {
    this->name = std::nullopt;
    return;
  }
  this->name = casted->id;
}

void KeywordItem::setParents() {
  this->key->parent = this;
  this->value->parent = this;
  this->key->setParents();
  this->value->setParents();
}

void KeywordItem::visitChildren(CodeVisitor *visitor) {
  this->key->visit(visitor);
  this->value->visit(visitor);
};

IterationStatement::IterationStatement(const std::shared_ptr<SourceFile> &file,
                                       TSNode node)
    : Node(file, node) {
  auto idList = ts_node_named_child(node, 0);
  std::vector<std::shared_ptr<Node>> ids;
  for (uint32_t i = 0; i < ts_node_named_child_count(idList); i++) {
    auto child = ts_node_named_child(idList, i);
    auto newNode = makeNode(file, child);
    ids.push_back(newNode);
  }
  this->ids = ids;
  this->expression = makeNode(file, ts_node_named_child(node, 1));
  for (uint32_t i = 2; i < ts_node_named_child_count(node); i++) {
    auto stmt = makeNode(file, ts_node_named_child(node, i));
    if (stmt == nullptr) {
      continue;
    }
    this->stmts.push_back(stmt);
  }
}

void IterationStatement::visitChildren(CodeVisitor *visitor) {
  for (const auto &idExpr : this->ids) {
    idExpr->visit(visitor);
  }
  this->expression->visit(visitor);
  for (const auto &stmt : this->stmts) {
    stmt->visit(visitor);
  }
}

void IterationStatement::setParents() {
  for (const auto &idExpr : this->ids) {
    idExpr->parent = this;
    idExpr->setParents();
  }
  this->expression->parent = this;
  this->expression->setParents();
  for (const auto &stmt : this->stmts) {
    stmt->parent = this;
    stmt->setParents();
  }
}

AssignmentStatement::AssignmentStatement(
    const std::shared_ptr<SourceFile> &file, TSNode node)
    : Node(file, node) {
  this->lhs = makeNode(file, ts_node_named_child(node, 0));
  const auto opNode = ts_node_named_child(node, 1);
  switch (ts_node_symbol(ts_node_child(opNode, 0))) {
  case anon_sym_EQ:
    this->op = AssignmentOperator::Equals;
    break;
  case anon_sym_STAR_EQ:
    this->op = AssignmentOperator::MulEquals;
    break;
  case anon_sym_SLASH_EQ:
    this->op = AssignmentOperator::DivEquals;
    break;
  case anon_sym_PERCENT_EQ:
    this->op = AssignmentOperator::ModEquals;
    break;
  case anon_sym_PLUS_EQ:
    this->op = AssignmentOperator::PlusEquals;
    break;
  case anon_sym_DASH_EQ:
    this->op = AssignmentOperator::MinusEquals;
    break;
  default:
    this->op = AssignmentOperator::AssignmentOpOther;
  }
  this->rhs = makeNode(file, ts_node_named_child(node, 2));
}

void AssignmentStatement::setParents() {
  this->lhs->parent = this;
  this->rhs->parent = this;
  this->lhs->setParents();
  this->rhs->setParents();
}

void AssignmentStatement::visitChildren(CodeVisitor *visitor) {
  this->lhs->visit(visitor);
  this->rhs->visit(visitor);
}

BinaryExpression::BinaryExpression(const std::shared_ptr<SourceFile> &file,
                                   TSNode node)
    : Node(file, node) {
  this->lhs = makeNode(file, ts_node_named_child(node, 0));
  auto ncc = ts_node_named_child_count(node);
  const auto opNode = (ncc == 2 ? ts_node_child : ts_node_named_child)(node, 1);
  switch (ts_node_symbol(opNode)) {
  case sym_equ_operator:
    switch (ts_node_symbol(ts_node_child(opNode, 0))) {
    case anon_sym_EQ_EQ:
      this->op = BinaryOperator::EqualsEquals;
      break;
    case anon_sym_BANG_EQ:
      this->op = BinaryOperator::NotEquals;
      break;
    default:
      std::unreachable();
    }
    break;
  case sym_mult_operator:
  case sym_add_operator:
    switch (ts_node_symbol(ts_node_child(opNode, 0))) {
    case anon_sym_PLUS:
      this->op = BinaryOperator::Plus;
      break;
    case anon_sym_DASH:
      this->op = BinaryOperator::Minus;
      break;
    case anon_sym_STAR:
      this->op = BinaryOperator::Mul;
      break;
    case anon_sym_SLASH:
      this->op = BinaryOperator::Div;
      break;
    case anon_sym_PERCENT:
      this->op = BinaryOperator::Modulo;
      break;
    default:
      std::unreachable();
    }
    break;
  case sym_rel_operator:
    switch (ts_node_symbol(ts_node_child(opNode, 0))) {
    case anon_sym_GT:
      this->op = BinaryOperator::Gt;
      break;
    case anon_sym_LT:
      this->op = BinaryOperator::Lt;
      break;
    case anon_sym_GT_EQ:
      this->op = BinaryOperator::Ge;
      break;
    case anon_sym_LT_EQ:
      this->op = BinaryOperator::Le;
      break;
    case anon_sym_in:
      this->op = BinaryOperator::In;
      break;
    case anon_sym_not:
      this->op = BinaryOperator::NotIn;
      break;
    default:
      std::unreachable();
    }
    break;
  case anon_sym_and:
    this->op = BinaryOperator::And;
    break;
  case anon_sym_or:
    this->op = BinaryOperator::Or;
    break;
  default:
    this->op = BinaryOperator::BinOpOther;
  }
  this->rhs = makeNode(file, ts_node_named_child(node, ncc == 2 ? 1 : 2));
}

void BinaryExpression::setParents() {
  this->lhs->parent = this;
  this->rhs->parent = this;
  this->lhs->setParents();
  this->rhs->setParents();
}

void BinaryExpression::visitChildren(CodeVisitor *visitor) {
  this->lhs->visit(visitor);
  this->rhs->visit(visitor);
}

UnaryExpression::UnaryExpression(const std::shared_ptr<SourceFile> &file,
                                 TSNode node)
    : Node(file, node) {
  const auto opNode = ts_node_child(node, 0);
  switch (ts_node_symbol(opNode)) {
  case anon_sym_not:
    this->op = UnaryOperator::Not;
    break;
  case anon_sym_BANG:
    this->op = UnaryOperator::ExclamationMark;
    break;
  case anon_sym_DASH:
    this->op = UnaryOperator::UnaryMinus;
    break;
  default:
    this->op = UnaryOperator::UnaryOther;
  }
  this->expression = makeNode(file, ts_node_named_child(node, 0));
}

void UnaryExpression::setParents() {
  this->expression->parent = this;
  this->expression->setParents();
}

void UnaryExpression::visitChildren(CodeVisitor *visitor) {
  this->expression->visit(visitor);
}

StringLiteral::StringLiteral(const std::shared_ptr<SourceFile> &file,
                             TSNode node)
    : Node(file, node) {
  const auto &typeNode = ts_node_child(node, 0);
  switch (ts_node_symbol(typeNode)) {
  case sym_string_multiline:
  case sym_string_simple:
    this->isFormat = false;
    this->id =
        file->extractNodeValue(ts_node_end_byte(ts_node_child(typeNode, 0)),
                               ts_node_start_byte(ts_node_child(typeNode, 1)));
    break;
  case sym_string_format_multiline:
  case sym_string_format: {
    this->isFormat = true;
    auto childNode = ts_node_child(typeNode, 0);
    this->id =
        file->extractNodeValue(ts_node_end_byte(ts_node_child(childNode, 0)),
                               ts_node_start_byte(ts_node_child(childNode, 1)));
    break;
  }
  default:
    std::unreachable();
  }
}

void StringLiteral::setParents() {}

void StringLiteral::visitChildren(CodeVisitor * /*visitor*/) {}

IdExpression::IdExpression(const std::shared_ptr<SourceFile> &file, TSNode node)
    : Node(file, node) {
  this->id = file->extractNodeValue(node);
}

void IdExpression::visitChildren(CodeVisitor * /*visitor*/) {}

void IdExpression::setParents() {}

BooleanLiteral::BooleanLiteral(const std::shared_ptr<SourceFile> &file,
                               TSNode node)
    : Node(file, node) {
  const auto diff = ts_node_end_byte(node) - ts_node_start_byte(node);
  this->value = diff == sizeof("true") - 1;
}

void BooleanLiteral::setParents() {}

void BooleanLiteral::visitChildren(CodeVisitor * /*visitor*/) {}

IntegerLiteral::IntegerLiteral(const std::shared_ptr<SourceFile> &file,
                               TSNode node)
    : Node(file, node) {
  this->value = file->extractNodeValue(node);
  if (this->value.starts_with("0x") || this->value.starts_with("0X")) {
    this->valueAsInt = std::stoull(this->value, nullptr, 16);
  } else if (this->value.starts_with("0b") || this->value.starts_with("0B")) {
    this->valueAsInt = std::stoull(this->value.substr(2), nullptr, 2);
  } else if (this->value.starts_with("0O") || this->value.starts_with("0o")) {
    this->valueAsInt = std::stoull(this->value.substr(2), nullptr, 8);
  } else if (!this->value.empty()) {
    this->valueAsInt = std::stoull(this->value);
  }
}

void IntegerLiteral::setParents() {}

void IntegerLiteral::visitChildren(CodeVisitor * /*visitor*/) {}

ContinueNode::ContinueNode(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(std::move(file), node) {}

void ContinueNode::setParents() {}

void ContinueNode::visitChildren(CodeVisitor * /*visitor*/) {}

BreakNode::BreakNode(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(std::move(file), node) {}

void BreakNode::visitChildren(CodeVisitor * /*visitor*/) {}

void BreakNode::setParents() {}

SelectionStatement::SelectionStatement(const std::shared_ptr<SourceFile> &file,
                                       TSNode node)
    : Node(file, node) {
  auto childCount = ts_node_child_count(node);
  uint32_t idx = 0;
  std::shared_ptr<Node> sI = nullptr;
  std::vector<std::shared_ptr<Node>> tmp;
  std::vector<std::shared_ptr<Node>> cs;
  std::vector<std::vector<std::shared_ptr<Node>>> bb;
  while (idx < childCount) {
    auto c = ts_node_child(node, idx);
    const auto nodeType = ts_node_symbol(c);
    if (nodeType == anon_sym_if && !sI) {
      while (ts_node_symbol(ts_node_child(node, idx + 1)) == sym__comment) {
        idx++;
      }
      sI = makeNode(file, ts_node_child(node, idx + 1));
      idx += 1;
    } else if (nodeType == anon_sym_elif) {
      bb.push_back(tmp);
      while (ts_node_symbol(ts_node_child(node, idx + 1)) == sym__comment) {
        idx++;
      }
      tmp = {};
      cs.push_back(makeNode(file, ts_node_child(node, idx + 1)));
      idx++;
    } else if (nodeType == anon_sym_else) {
      bb.push_back(tmp);
      tmp = {};
    } else if (nodeType != sym__comment && ts_node_named_child_count(c) == 1) {
      const auto cChildType = ts_node_symbol(ts_node_named_child(c, 0));
      if (cChildType != sym__comment) {
        tmp.push_back(makeNode(file, c));
      }
    }
    idx++;
  }
  bb.push_back(tmp);
  this->conditions = cs;
  this->conditions.insert(this->conditions.begin(), sI);
  this->blocks = bb;
}

void SelectionStatement::visitChildren(CodeVisitor *visitor) {
  for (const auto &condition : this->conditions) {
    condition->visit(visitor);
  }
  for (const auto &block : this->blocks) {
    for (const auto &stmt : block) {
      stmt->visit(visitor);
    }
  }
}

void SelectionStatement::setParents() {
  for (const auto &condition : this->conditions) {
    condition->parent = this;
    condition->setParents();
  }
  for (const auto &block : this->blocks) {
    for (const auto &stmt : block) {
      stmt->parent = this;
      stmt->setParents();
    }
  }
}

void ErrorNode::visitChildren(CodeVisitor * /*visitor*/) {}

void ErrorNode::setParents() {}

void ErrorNode::visit(CodeVisitor *visitor) { visitor->visitErrorNode(this); }

void ContinueNode::visit(CodeVisitor *visitor) {
  visitor->visitContinueNode(this);
}

void BreakNode::visit(CodeVisitor *visitor) { visitor->visitBreakNode(this); }

void ArgumentList::visit(CodeVisitor *visitor) {
  visitor->visitArgumentList(this);
}

void ArrayLiteral::visit(CodeVisitor *visitor) {
  visitor->visitArrayLiteral(this);
}

void AssignmentStatement::visit(CodeVisitor *visitor) {
  visitor->visitAssignmentStatement(this);
}

void BinaryExpression::visit(CodeVisitor *visitor) {
  visitor->visitBinaryExpression(this);
}

void BooleanLiteral::visit(CodeVisitor *visitor) {
  visitor->visitBooleanLiteral(this);
}

void BuildDefinition::visit(CodeVisitor *visitor) {
  visitor->visitBuildDefinition(this);
}

void ConditionalExpression::visit(CodeVisitor *visitor) {
  visitor->visitConditionalExpression(this);
}

void DictionaryLiteral::visit(CodeVisitor *visitor) {
  visitor->visitDictionaryLiteral(this);
}

void FunctionExpression::visit(CodeVisitor *visitor) {
  visitor->visitFunctionExpression(this);
}

void IdExpression::visit(CodeVisitor *visitor) {
  visitor->visitIdExpression(this);
}

void IntegerLiteral::visit(CodeVisitor *visitor) {
  visitor->visitIntegerLiteral(this);
}

void IterationStatement::visit(CodeVisitor *visitor) {
  visitor->visitIterationStatement(this);
}

void KeyValueItem::visit(CodeVisitor *visitor) {
  visitor->visitKeyValueItem(this);
}

void KeywordItem::visit(CodeVisitor *visitor) {
  visitor->visitKeywordItem(this);
}

void MethodExpression::visit(CodeVisitor *visitor) {
  visitor->visitMethodExpression(this);
}

void SelectionStatement::visit(CodeVisitor *visitor) {
  visitor->visitSelectionStatement(this);
}

void StringLiteral::visit(CodeVisitor *visitor) {
  visitor->visitStringLiteral(this);
}

void SubscriptExpression::visit(CodeVisitor *visitor) {
  visitor->visitSubscriptExpression(this);
}

void UnaryExpression::visit(CodeVisitor *visitor) {
  visitor->visitUnaryExpression(this);
}

std::shared_ptr<Node> makeNode(const std::shared_ptr<SourceFile> &file,
                               TSNode node) {
  auto symbol = ts_node_symbol(node);
  if (symbol == sym_argument_list) {
    return std::make_shared<ArgumentList>(file, node);
  }
  if (symbol == sym_array_literal) {
    return std::make_shared<ArrayLiteral>(file, node);
  }
  if (symbol == sym_assignment_statement) {
    return std::make_shared<AssignmentStatement>(file, node);
  }
  if (symbol == sym_binary_expression) {
    return std::make_shared<BinaryExpression>(file, node);
  }
  if (symbol == sym_boolean_literal) {
    return std::make_shared<BooleanLiteral>(file, node);
  }
  if (symbol == sym_build_definition) {
    return std::make_shared<BuildDefinition>(file, node);
  }
  if (symbol == sym_dictionary_literal) {
    return std::make_shared<DictionaryLiteral>(file, node);
  }
  if (symbol == sym_function_expression) {
    return std::make_shared<FunctionExpression>(file, node);
  }
  if (symbol == sym_id_expression || symbol == sym_function_id ||
      symbol == sym_keyword_arg_key) {
    return std::make_shared<IdExpression>(file, node);
  }
  if (symbol == sym_integer_literal) {
    return std::make_shared<IntegerLiteral>(file, node);
  }
  if (symbol == sym_iteration_statement) {
    return std::make_shared<IterationStatement>(file, node);
  }
  if (symbol == sym_key_value_item) {
    return std::make_shared<KeyValueItem>(file, node);
  }
  if (symbol == sym_keyword_item) {
    return std::make_shared<KeywordItem>(file, node);
  }
  if (symbol == sym_method_expression) {
    return std::make_shared<MethodExpression>(file, node);
  }
  if (symbol == sym_selection_statement) {
    return std::make_shared<SelectionStatement>(file, node);
  }
  if (symbol == sym_string_literal) {
    return std::make_shared<StringLiteral>(file, node);
  }
  if (symbol == sym_subscript_expression) {
    return std::make_shared<SubscriptExpression>(file, node);
  }
  if (symbol == sym_unary_expression) {
    return std::make_shared<UnaryExpression>(file, node);
  }
  if (symbol == sym_conditional_expression) {
    return std::make_shared<ConditionalExpression>(file, node);
  }
  if (symbol == sym_source_file) {
    return std::make_shared<BuildDefinition>(file,
                                             ts_node_named_child(node, 0));
  }
  if (symbol == sym_statement && ts_node_named_child_count(node) == 1) {
    return makeNode(file, ts_node_named_child(node, 0));
  }
  if (symbol == sym_expression && ts_node_named_child_count(node) == 1) {
    return makeNode(file, ts_node_named_child(node, 0));
  }
  if (symbol == sym_condition && ts_node_named_child_count(node) == 1) {
    return makeNode(file, ts_node_named_child(node, 0));
  }
  if (symbol == sym_primary_expression &&
      ts_node_named_child_count(node) == 1) {
    return makeNode(file, ts_node_named_child(node, 0));
  }
  if (symbol == sym_statement && ts_node_named_child_count(node) == 1) {
    return makeNode(file, ts_node_named_child(node, 0));
  }
  if (symbol == sym_statement && ts_node_named_child_count(node) == 0) {
    return nullptr;
  }
  if (symbol == sym_jump_statement) {
    const auto diff = ts_node_end_byte(node) - ts_node_start_byte(node);
    if (diff == sizeof("break") - 1) {
      return std::make_shared<BreakNode>(file, node);
    }
    if (diff == sizeof("continue") - 1) {
      return std::make_shared<ContinueNode>(file, node);
    }
  }
  const auto *nodeType = ts_node_type(node);
  return std::make_shared<ErrorNode>(
      file, node, std::format("Unknown node_type '{}'", nodeType));
}

std::vector<std::string> extractTextBetweenAtSymbols(const std::string &text) {
  std::vector<std::string> matches;

  std::smatch match;
  std::string tempText = text;

  while (std::regex_search(tempText, match, FORMAT_STRING_REGEX)) {
    const std::string &matchedStr = match.str(1);
    size_t const startPos = match.position();
    size_t const endPos = startPos + matchedStr.length() +
                          2; // Including the surrounding @ symbols

    if ((startPos != 0 && (std::isdigit(tempText[startPos - 1]) != 0)) ||
        (endPos != tempText.length() &&
         (std::isdigit(tempText[endPos]) != 0))) {
      tempText = match.suffix().str();
      continue;
    }

    matches.emplace_back(matchedStr);
    tempText = match.suffix().str();
  }

  return matches;
}

std::set<uint64_t> extractIntegersBetweenAtSymbols(const std::string &text) {
  std::set<uint64_t> integers;

  std::sregex_iterator iter(text.begin(), text.end(), STR_FORMAT_REGEX);
  std::sregex_iterator const end;

  while (iter != end) {
    const std::string &match = iter->str(1);
    integers.insert(std::stoull(match));
    ++iter;
  }

  return integers;
}
