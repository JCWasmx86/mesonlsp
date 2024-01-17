#include "semantictokensvisitor.hpp"

#include "log.hpp"
#include "node.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <format>
#include <regex>
#include <vector>

const static Logger LOG("SemanticTokensVisitor"); // NOLINT
static const std::regex
    FORMAT_STRING_REGEX("@([a-zA-Z_][a-zA-Z_\\d]*)@"); // NOLINT
static const std::regex STR_FORMAT_REGEX("@(\\d+)@");  // NOLINT

// TODO: Use enum
void SemanticTokensVisitor::makeSemanticToken(Node *node, size_t idx,
                                              uint64_t modifiers) {
  if (node->location.startLine != node->location.endLine) {
    return;
  }
  if (idx >= 8) {
    return;
  }
  tokens.push_back({node->location.startLine, node->location.startColumn,
                    node->location.endColumn - node->location.startColumn, idx,
                    modifiers});
}

std::vector<uint64_t> SemanticTokensVisitor::finish() {
  std::ranges::sort(this->tokens, [](const auto &lhs, const auto &rhs) {
    if (lhs[0] == rhs[0]) {
      return lhs[1] < rhs[1];
    }
    return lhs[0] < rhs[0];
  });
  std::vector<uint64_t> ret;
  uint64_t prevLine = 0;
  uint64_t prevChar = 0;

  LOG.info(std::format("Collected {} semantic tokens", this->tokens.size()));
  for (auto token : tokens) {
    auto line = token[0];
    auto startChar = (line == prevLine) ? (token[1] - prevChar) : token[1];
    auto length = token[2];
    auto tokenType = token[3];
    auto tokenModifiers = token[4];
    auto deltaLine = line - prevLine;
    prevLine = line;
    prevChar = token[1];

    ret.push_back(deltaLine);
    ret.push_back(startChar);
    ret.push_back(length);
    ret.push_back(tokenType);
    ret.push_back(tokenModifiers);
  }
  return ret;
}

void SemanticTokensVisitor::visitArgumentList(ArgumentList *node) {
  node->visitChildren(this);
}

void SemanticTokensVisitor::visitArrayLiteral(ArrayLiteral *node) {
  node->visitChildren(this);
}

void SemanticTokensVisitor::visitAssignmentStatement(
    AssignmentStatement *node) {
  node->visitChildren(this);
}

void SemanticTokensVisitor::visitBinaryExpression(BinaryExpression *node) {
  node->visitChildren(this);
}

void SemanticTokensVisitor::visitBooleanLiteral(BooleanLiteral *node) {
  node->visitChildren(this);
}

void SemanticTokensVisitor::visitBuildDefinition(BuildDefinition *node) {
  node->visitChildren(this);
}

void SemanticTokensVisitor::visitConditionalExpression(
    ConditionalExpression *node) {
  node->visitChildren(this);
}

void SemanticTokensVisitor::visitDictionaryLiteral(DictionaryLiteral *node) {
  node->visitChildren(this);
}

void SemanticTokensVisitor::visitFunctionExpression(FunctionExpression *node) {
  node->visitChildren(this);
  this->makeSemanticToken(node->id.get(), 3, 0);
}

void SemanticTokensVisitor::visitIdExpression(IdExpression *node) {
  node->visitChildren(this);
  auto exprId = node->id;
  if (exprId == "meson" || exprId == "host_machine" ||
      exprId == "target_machine" || exprId == "build_machine") {
    this->makeSemanticToken(node, 2, 0b11);
  }
}

void SemanticTokensVisitor::visitIntegerLiteral(IntegerLiteral *node) {
  node->visitChildren(this);
}

void SemanticTokensVisitor::visitIterationStatement(IterationStatement *node) {
  node->visitChildren(this);
}

void SemanticTokensVisitor::visitKeyValueItem(KeyValueItem *node) {
  node->visitChildren(this);
}

void SemanticTokensVisitor::visitKeywordItem(KeywordItem *node) {
  node->visitChildren(this);
}

void SemanticTokensVisitor::visitMethodExpression(MethodExpression *node) {
  node->visitChildren(this);
  this->makeSemanticToken(node->id.get(), 4, 0);
}

void SemanticTokensVisitor::visitSelectionStatement(SelectionStatement *node) {
  node->visitChildren(this);
}

void SemanticTokensVisitor::visitStringLiteral(StringLiteral *node) {
  node->visitChildren(this);
  const auto loc = node->location;
  if (node->isFormat) {
    std::sregex_iterator iter(node->id.begin(), node->id.end(),
                              FORMAT_STRING_REGEX);
    std::sregex_iterator const end;

    while (iter != end) {
      auto match = *iter;
      this->tokens.push_back(
          {loc.startLine,
           static_cast<unsigned long>(loc.startColumn + match.position() + 2),
           1, 1, 0});
      this->tokens.push_back(
          {loc.startLine,
           static_cast<unsigned long>(loc.startColumn + match.position() + 3),
           static_cast<unsigned long>(match.length() - 2), 2, 0});
      this->tokens.push_back(
          {loc.startLine,
           static_cast<unsigned long>(loc.startColumn + match.position() +
                                      match.length() + 1),
           1, 1});
      ++iter;
    }
  }
  if (loc.startLine != loc.endLine) {
    return;
  }
  auto *parentNode = node->parent;
  if (!parentNode) {
    return;
  }
  auto *asCall = dynamic_cast<MethodExpression *>(parentNode);
  if ((asCall == nullptr) || !asCall->method ||
      asCall->method->id() != "str.format") {
    return;
  }
  std::sregex_iterator iter(node->id.begin(), node->id.end(), STR_FORMAT_REGEX);
  std::sregex_iterator const end;

  while (iter != end) {
    auto match = *iter;
    this->tokens.push_back(
        {loc.startLine,
         static_cast<unsigned long>(loc.startColumn + match.position() + 2), 1,
         1, 0});
    this->tokens.push_back(
        {loc.startLine,
         static_cast<unsigned long>(loc.startColumn + match.position() + 3),
         static_cast<unsigned long>(match.length() - 2), 2, 0});
    this->tokens.push_back(
        {loc.startLine,
         static_cast<unsigned long>(loc.startColumn + match.position() +
                                    match.length() + 1),
         1, 1});
    ++iter;
  }
}

void SemanticTokensVisitor::visitSubscriptExpression(
    SubscriptExpression *node) {
  node->visitChildren(this);
}

void SemanticTokensVisitor::visitUnaryExpression(UnaryExpression *node) {
  node->visitChildren(this);
}

void SemanticTokensVisitor::visitErrorNode(ErrorNode *node) {
  node->visitChildren(this);
}

void SemanticTokensVisitor::visitBreakNode(BreakNode *node) {
  node->visitChildren(this);
}

void SemanticTokensVisitor::visitContinueNode(ContinueNode *node) {
  node->visitChildren(this);
}
