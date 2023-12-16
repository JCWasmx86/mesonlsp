#include "node.hpp"
#include "location.hpp"
#include "sourcefile.hpp"
#include <cstdint>
#include <cstring>
#include <format>
#include <memory>
#include <optional>
#include <tree_sitter/api.h>
#include <vector>

Node::Node(std::shared_ptr<SourceFile> file, TSNode node)
    : file(file), location(new Location(node)) {}

ArgumentList::ArgumentList(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(file, node) {
  for (uint32_t i = 0; i < ts_node_named_child_count(node); i++) {
    this->args.push_back(makeNode(file, ts_node_named_child(node, i)));
  }
}

void ArgumentList::visitChildren(CodeVisitor *visitor) {
  for (const auto &n : this->args) {
    n->visit(visitor);
  }
};

ArrayLiteral::ArrayLiteral(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(file, node) {
  for (uint32_t i = 0; i < ts_node_named_child_count(node); i++) {
    this->args.push_back(makeNode(file, ts_node_named_child(node, i)));
  }
}

void ArrayLiteral::visitChildren(CodeVisitor *visitor) {
  for (const auto &n : this->args) {
    n->visit(visitor);
  }
};

BuildDefinition::BuildDefinition(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(file, node) {
  for (uint32_t i = 0; i < ts_node_named_child_count(node); i++) {
    auto stmt = makeNode(file, ts_node_named_child(node, i));
    if (stmt) {
      this->stmts.push_back(stmt);
    }
  }
}

void BuildDefinition::visitChildren(CodeVisitor *visitor) {
  for (const auto &n : this->stmts) {
    n->visit(visitor);
  }
};

DictionaryLiteral::DictionaryLiteral(std::shared_ptr<SourceFile> file,
                                     TSNode node)
    : Node(file, node) {
  for (uint32_t i = 0; i < ts_node_named_child_count(node); i++) {
    this->values.push_back(makeNode(file, ts_node_named_child(node, i)));
  }
}

void DictionaryLiteral::visitChildren(CodeVisitor *visitor) {
  for (const auto &n : this->values) {
    n->visit(visitor);
  }
};

ConditionalExpression::ConditionalExpression(std::shared_ptr<SourceFile> file,
                                             TSNode node)
    : Node(file, node) {
  this->condition = makeNode(file, ts_node_named_child(node, 0));
  this->ifTrue = makeNode(file, ts_node_named_child(node, 1));
  this->ifFalse = makeNode(file, ts_node_named_child(node, 2));
}

void ConditionalExpression::visitChildren(CodeVisitor *visitor) {
  this->condition->visit(visitor);
  this->ifTrue->visit(visitor);
  this->ifFalse->visit(visitor);
};

SubscriptExpression::SubscriptExpression(std::shared_ptr<SourceFile> file,
                                         TSNode node)
    : Node(file, node) {
  this->outer = makeNode(file, ts_node_named_child(node, 0));
  this->inner = makeNode(file, ts_node_named_child(node, 1));
}

void SubscriptExpression::visitChildren(CodeVisitor *visitor) {
  this->outer->visit(visitor);
  this->inner->visit(visitor);
};

MethodExpression::MethodExpression(std::shared_ptr<SourceFile> file,
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

FunctionExpression::FunctionExpression(std::shared_ptr<SourceFile> file,
                                       TSNode node)
    : Node(file, node) {
  this->id = makeNode(file, ts_node_named_child(node, 0));
  if (ts_node_named_child_count(node) != 1) {
    this->args = makeNode(file, ts_node_named_child(node, 1));
  }
}

void FunctionExpression::visitChildren(CodeVisitor *visitor) {
  this->id->visit(visitor);
  if (this->args) {
    this->args->visit(visitor);
  }
};

KeyValueItem::KeyValueItem(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(file, node) {
  this->key = makeNode(file, ts_node_named_child(node, 0));
  this->value = makeNode(file, ts_node_named_child(node, 1));
}

void KeyValueItem::visitChildren(CodeVisitor *visitor) {
  this->key->visit(visitor);
  this->value->visit(visitor);
};

KeywordItem::KeywordItem(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(file, node) {
  this->key = makeNode(file, ts_node_named_child(node, 0));
  this->value = makeNode(file, ts_node_named_child(node, 1));
  auto casted = dynamic_cast<IdExpression *>(this->key.get());
  if (casted == nullptr) {
    this->name = std::nullopt;
    return;
  }
  this->name = casted->id;
}

void KeywordItem::visitChildren(CodeVisitor *visitor) {
  this->key->visit(visitor);
  this->value->visit(visitor);
};

IterationStatement::IterationStatement(std::shared_ptr<SourceFile> file,
                                       TSNode node)
    : Node(file, node) {
  auto idList = ts_node_named_child(node, 0);
  for (uint32_t i = 0; i < ts_node_named_child_count(idList); i++) {
    this->ids.push_back(makeNode(file, ts_node_named_child(idList, i)));
  }
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
  for (auto id : this->ids) {
    id->visit(visitor);
  }
  this->expression->visit(visitor);
  for (auto stmt : this->stmts) {
    stmt->visit(visitor);
  }
}

AssignmentStatement::AssignmentStatement(std::shared_ptr<SourceFile> file,
                                         TSNode node)
    : Node(file, node) {
  this->lhs = makeNode(file, ts_node_named_child(node, 0));
  auto opStr = file->extractNodeValue(ts_node_named_child(node, 0));
  if (opStr == "=") {
    this->op = AssignmentOperator::Equals;
  } else if (opStr == "*=") {
    this->op = AssignmentOperator::MulEquals;
  } else if (opStr == "/=") {
    this->op = AssignmentOperator::DivEquals;
  } else if (opStr == "%=") {
    this->op = AssignmentOperator::ModEquals;
  } else if (opStr == "+=") {
    this->op = AssignmentOperator::PlusEquals;
  } else if (opStr == "-=") {
    this->op = AssignmentOperator::MinusEquals;
  } else {
    this->op = AssignmentOpOther;
  }
  this->rhs = makeNode(file, ts_node_named_child(node, 2));
}

void AssignmentStatement::visitChildren(CodeVisitor *visitor) {
  this->lhs->visit(visitor);
  this->rhs->visit(visitor);
}

BinaryExpression::BinaryExpression(std::shared_ptr<SourceFile> file,
                                   TSNode node)
    : Node(file, node) {
  this->lhs = makeNode(file, ts_node_named_child(node, 0));
  auto ncc = ts_node_named_child_count(node);
  auto opStr = file->extractNodeValue(
      (ncc == 2 ? ts_node_child : ts_node_named_child)(node, 1));
  if (opStr == "+") {
    this->op = BinaryOperator::Plus;
  } else if (opStr == "-") {
    this->op = BinaryOperator::Minus;
  } else if (opStr == "*") {
    this->op = BinaryOperator::Mul;
  } else if (opStr == "/") {
    this->op = BinaryOperator::Div;
  } else if (opStr == "%") {
    this->op = BinaryOperator::Modulo;
  } else if (opStr == "==") {
    this->op = BinaryOperator::EqualsEquals;
  } else if (opStr == "!=") {
    this->op = BinaryOperator::NotEquals;
  } else if (opStr == ">") {
    this->op = BinaryOperator::Gt;
  } else if (opStr == "<") {
    this->op = BinaryOperator::Lt;
  } else if (opStr == ">=") {
    this->op = BinaryOperator::Ge;
  } else if (opStr == "<=") {
    this->op = BinaryOperator::Le;
  } else if (opStr == "in") {
    this->op = BinaryOperator::In;
  } else if (opStr == "not in") {
    this->op = BinaryOperator::NotIn;
  } else if (opStr == "and") {
    this->op = BinaryOperator::And;
  } else if (opStr == "or") {
    this->op = BinaryOperator::Or;
  } else {
    this->op = BinaryOperator::BinOpOther;
  }
  this->rhs = makeNode(file, ts_node_named_child(node, ncc == 2 ? 1 : 2));
}

void BinaryExpression::visitChildren(CodeVisitor *visitor) {
  this->lhs->visit(visitor);
  this->rhs->visit(visitor);
}

UnaryExpression::UnaryExpression(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(file, node) {
  auto opStr = file->extractNodeValue(ts_node_child(node, 0));
  if (opStr == "not") {
    this->op = UnaryOperator::Not;
  } else if (opStr == "!") {
    this->op = UnaryOperator::ExclamationMark;
  } else if (opStr == "-") {
    this->op = UnaryOperator::UnaryMinus;
  } else {
    this->op = UnaryOther;
  }
  this->expression = makeNode(file, ts_node_named_child(node, 0));
}

void UnaryExpression::visitChildren(CodeVisitor *visitor) {
  this->expression->visit(visitor);
}

std::string extractValueFromMesonStringLiteral(const std::string &mesonString) {
  std::string extractedValue;
  size_t startPos = std::string::npos;
  size_t endPos = std::string::npos;

  // Check if it's a multi-line format string (f''' ... ''')
  if (mesonString.size() >= 7 && mesonString.substr(0, 4) == "f'''") {
    startPos = 4;
    endPos = mesonString.size() - 3;
  }
  // Check if it's a single-line format string (f' ... ')
  else if (mesonString.size() >= 4 && mesonString.substr(0, 2) == "f'") {
    startPos = 2;
    endPos = mesonString.size() - 1;
  }
  // Check if it's a multi-line string (''' ... ''')
  else if (mesonString.size() >= 6 && mesonString.substr(0, 3) == "'''") {
    startPos = 3;
    endPos = mesonString.size() - 3;
  }
  // Check if it's a single-line string (' ... ')
  else if (mesonString.size() >= 2 && mesonString.front() == '\'' &&
           mesonString.back() == '\'') {
    startPos = 1;
    endPos = mesonString.size() - 1;
  }
  if (startPos != std::string::npos && endPos != std::string::npos) {
    return mesonString.substr(startPos, endPos - startPos);
  }

  return mesonString;
}

StringLiteral::StringLiteral(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(file, node) {
  this->isFormat =
      strcmp(ts_node_type(ts_node_child(node, 0)), "string_format") == 0;
  auto id = file->extractNodeValue(node);
  this->id = extractValueFromMesonStringLiteral(id);
}

void StringLiteral::visitChildren(CodeVisitor *visitor) {}

IdExpression::IdExpression(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(file, node) {
  this->id = file->extractNodeValue(node);
}

void IdExpression::visitChildren(CodeVisitor *visitor) {}

BooleanLiteral::BooleanLiteral(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(file, node) {
  this->value = file->extractNodeValue(node) == "true";
}

void BooleanLiteral::visitChildren(CodeVisitor *visitor) {}

IntegerLiteral::IntegerLiteral(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(file, node) {
  this->value = file->extractNodeValue(node);
}

void IntegerLiteral::visitChildren(CodeVisitor *visitor) {}

ContinueNode::ContinueNode(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(file, node) {}

void ContinueNode::visitChildren(CodeVisitor *visitor) {}

BreakNode::BreakNode(std::shared_ptr<SourceFile> file, TSNode node)
    : Node(file, node) {}

void BreakNode::visitChildren(CodeVisitor *visitor) {}

SelectionStatement::SelectionStatement(std::shared_ptr<SourceFile> file,
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
    auto sv = file->extractNodeValue(c);
    auto nodeType = ts_node_type(c);
    if ((sv == "if" || strcmp(nodeType, "if") == 0) && !sI) {
      while (file->extractNodeValue(ts_node_child(node, idx + 1)) ==
             "comment") {
        idx++;
      }
      sI = makeNode(file, ts_node_child(node, idx + 1));
      idx += 1;
    } else if (sv == "elif") {
      bb.push_back(tmp);
      while (file->extractNodeValue(ts_node_child(node, idx + 1)) ==
             "comment") {
        idx++;
      }
      tmp = {};
      cs.push_back(makeNode(file, ts_node_child(node, idx + 1)));
      idx++;
    } else if (sv == "else") {
      bb.push_back(tmp);
      tmp = {};
    } else if (sv != "comment" && ts_node_named_child_count(c) == 1) {
      auto cChildType = ts_node_type(ts_node_named_child(c, 0));
      if (strcmp(cChildType, "comment") != 0) {
        tmp.push_back(makeNode(file, c));
      }
    }
    idx++;
  }
}

void SelectionStatement::visitChildren(CodeVisitor *visitor) {
  for (const auto &condition : this->conditions) {
    condition->visit(visitor);
  }
  for (const auto &b : this->blocks) {
    for (const auto &bb : b) {
      bb->visit(visitor);
    }
  }
}

void ErrorNode::visitChildren(CodeVisitor *visitor) {}
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

std::shared_ptr<Node> makeNode(std::shared_ptr<SourceFile> file, TSNode node) {
  auto nodeType = ts_node_type(node);
  if (strcmp(nodeType, "argument_list") == 0) {
    return std::make_shared<ArgumentList>(file, node);
  }
  if (strcmp(nodeType, "array_literal") == 0) {
    return std::make_shared<ArrayLiteral>(file, node);
  }
  if (strcmp(nodeType, "assignment_statement") == 0) {
    return std::make_shared<AssignmentStatement>(file, node);
  }
  if (strcmp(nodeType, "binary_expression") == 0) {
    return std::make_shared<BinaryExpression>(file, node);
  }
  if (strcmp(nodeType, "boolean_literal") == 0) {
    return std::make_shared<BooleanLiteral>(file, node);
  }
  if (strcmp(nodeType, "build_definition") == 0) {
    return std::make_shared<BuildDefinition>(file, node);
  }
  if (strcmp(nodeType, "dictionary_literal") == 0) {
    return std::make_shared<DictionaryLiteral>(file, node);
  }
  if (strcmp(nodeType, "function_expression") == 0) {
    return std::make_shared<FunctionExpression>(file, node);
  }
  if (strcmp(nodeType, "id_expression") == 0 ||
      strcmp(nodeType, "function_id") == 0 ||
      strcmp(nodeType, "keyword_arg_key") == 0) {
    return std::make_shared<IdExpression>(file, node);
  }
  if (strcmp(nodeType, "integer_literal") == 0) {
    return std::make_shared<IntegerLiteral>(file, node);
  }
  if (strcmp(nodeType, "iteration_statement") == 0) {
    return std::make_shared<IterationStatement>(file, node);
  }
  if (strcmp(nodeType, "key_value_item") == 0) {
    return std::make_shared<KeyValueItem>(file, node);
  }
  if (strcmp(nodeType, "keyword_item") == 0) {
    return std::make_shared<KeywordItem>(file, node);
  }
  if (strcmp(nodeType, "method_expression") == 0) {
    return std::make_shared<MethodExpression>(file, node);
  }
  if (strcmp(nodeType, "selection_statement") == 0) {
    return std::make_shared<SelectionStatement>(file, node);
  }
  if (strcmp(nodeType, "string_literal") == 0) {
    return std::make_shared<StringLiteral>(file, node);
  }
  if (strcmp(nodeType, "subscript_expression") == 0) {
    return std::make_shared<SubscriptExpression>(file, node);
  }
  if (strcmp(nodeType, "unary_expression") == 0) {
    return std::make_shared<UnaryExpression>(file, node);
  }
  if (strcmp(nodeType, "conditional_expression") == 0) {
    return std::make_shared<ConditionalExpression>(file, node);
  }
  if (strcmp(nodeType, "source_file") == 0) {
    return std::make_shared<BuildDefinition>(file,
                                             ts_node_named_child(node, 0));
  }
  if (strcmp(nodeType, "statement") == 0 &&
      ts_node_named_child_count(node) == 1) {
    return makeNode(file, ts_node_named_child(node, 0));
  }
  if (strcmp(nodeType, "expression") == 0 &&
      ts_node_named_child_count(node) == 1) {
    return makeNode(file, ts_node_named_child(node, 0));
  }
  if (strcmp(nodeType, "condition") == 0 &&
      ts_node_named_child_count(node) == 1) {
    return makeNode(file, ts_node_named_child(node, 0));
  }
  if (strcmp(nodeType, "primary_expression") == 0 &&
      ts_node_named_child_count(node) == 1) {
    return makeNode(file, ts_node_named_child(node, 0));
  }
  if (strcmp(nodeType, "statement") == 0 &&
      ts_node_named_child_count(node) == 1) {
    return makeNode(file, ts_node_named_child(node, 0));
  }
  if (strcmp(nodeType, "statement") == 0 &&
      ts_node_named_child_count(node) == 0) {
    return nullptr;
  }
  if (strcmp(nodeType, "jump_statement") == 0) {
    auto content = file->extractNodeValue(node);
    if (content == "break") {
      return std::make_shared<BreakNode>(file, node);
    }
    if (content == "continue") {
      return std::make_shared<ContinueNode>(file, node);
    }
  }
  return std::make_shared<ErrorNode>(
      file, node, std::format("Unknown node_type '{}'", nodeType));
}
