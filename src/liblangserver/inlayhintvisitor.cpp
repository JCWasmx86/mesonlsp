#include "inlayhintvisitor.hpp"

#include "lsptypes.hpp"
#include "node.hpp"
#include "type.hpp"
#include "utils.hpp"

#include <algorithm>
#include <format>
#include <memory>
#include <string>
#include <vector>

void InlayHintVisitor::visitArgumentList(ArgumentList *node) {
  node->visitChildren(this);
}

void InlayHintVisitor::visitArrayLiteral(ArrayLiteral *node) {
  node->visitChildren(this);
}

void InlayHintVisitor::visitAssignmentStatement(AssignmentStatement *node) {
  node->visitChildren(this);
  this->makeHint(node->lhs.get());
}

void InlayHintVisitor::visitBinaryExpression(BinaryExpression *node) {
  node->visitChildren(this);
}

void InlayHintVisitor::visitBooleanLiteral(BooleanLiteral *node) {
  node->visitChildren(this);
}

void InlayHintVisitor::visitBuildDefinition(BuildDefinition *node) {
  node->visitChildren(this);
}

void InlayHintVisitor::visitConditionalExpression(ConditionalExpression *node) {
  node->visitChildren(this);
}

void InlayHintVisitor::visitDictionaryLiteral(DictionaryLiteral *node) {
  node->visitChildren(this);
}

void InlayHintVisitor::visitFunctionExpression(FunctionExpression *node) {
  node->visitChildren(this);
}

void InlayHintVisitor::visitIdExpression(IdExpression *node) {
  node->visitChildren(this);
}

void InlayHintVisitor::visitIntegerLiteral(IntegerLiteral *node) {
  node->visitChildren(this);
}

void InlayHintVisitor::visitIterationStatement(IterationStatement *node) {
  node->visitChildren(this);
  for (const auto &idexpr : node->ids) {
    this->makeHint(idexpr.get());
  }
}

void InlayHintVisitor::visitKeyValueItem(KeyValueItem *node) {
  node->visitChildren(this);
}

void InlayHintVisitor::visitKeywordItem(KeywordItem *node) {
  node->visitChildren(this);
}

void InlayHintVisitor::visitMethodExpression(MethodExpression *node) {
  node->visitChildren(this);
}

void InlayHintVisitor::visitSelectionStatement(SelectionStatement *node) {
  node->visitChildren(this);
}

void InlayHintVisitor::visitStringLiteral(StringLiteral *node) {
  node->visitChildren(this);
}

void InlayHintVisitor::visitSubscriptExpression(SubscriptExpression *node) {
  node->visitChildren(this);
}

void InlayHintVisitor::visitUnaryExpression(UnaryExpression *node) {
  node->visitChildren(this);
}

void InlayHintVisitor::visitErrorNode(ErrorNode *node) {
  node->visitChildren(this);
}

void InlayHintVisitor::visitBreakNode(BreakNode *node) {
  node->visitChildren(this);
}

void InlayHintVisitor::visitContinueNode(ContinueNode *node) {
  node->visitChildren(this);
}

void InlayHintVisitor::makeHint(Node *node) {
  auto pos = LSPPosition(node->location.startLine, node->location.endColumn);
  auto text = ":" + this->prettify(node->types, 0);
  this->hints.emplace_back(pos, text);
}

std::string
InlayHintVisitor::prettify(const std::vector<std::shared_ptr<Type>> &types,
                           int depth) {
  std::vector<std::string> strs;
  for (const auto &type : types) {
    if (dynamic_cast<Disabler *>(type.get()) && types.size() > 1) {
      continue;
    }
    auto *asList = dynamic_cast<List *>(type.get());
    if (asList) {
      if (depth >= 1) {
        strs.emplace_back("list(...)");
      } else {
        strs.push_back(
            std::format("list({})", prettify(asList->types, depth + 1)));
      }
      continue;
    }
    auto *asDict = dynamic_cast<Dict *>(type.get());
    if (asDict) {
      if (depth >= 1) {
        strs.emplace_back("dict(...)");
      } else {
        strs.push_back(
            std::format("dict({})", prettify(asDict->types, depth + 1)));
      }
      continue;
    }
    if (dynamic_cast<Subproject *>(type.get())) {
      strs.emplace_back("subproject");
      continue;
    }
    strs.push_back(type->toString());
  }
  std::ranges::sort(strs);
  return joinStrings(strs, '|');
}
