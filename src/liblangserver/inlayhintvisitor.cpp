#include "inlayhintvisitor.hpp"

#include "lsptypes.hpp"
#include "node.hpp"
#include "polyfill.hpp"
#include "type.hpp"
#include "utils.hpp"

#include <algorithm>
#include <cstddef>
#include <memory>
#include <set>
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
  if (!node->function || !node->args ||
      node->args->type != NodeType::ARGUMENT_LIST) {
    return;
  }
  auto args = node->function->args;
  const auto *al = static_cast<const ArgumentList *>(node->args.get());
  auto posIdx = 0;
  for (const auto &arg : al->args) {
    if (arg->type == NodeType::KEYWORD_ITEM ||
        arg->type == NodeType::ERROR_NODE) {
      continue;
    }
    const auto *posArg = node->function->posArg(posIdx);
    if (!posArg) {
      break;
    }
    auto pos = LSPPosition(arg->location.startLine, arg->location.startColumn);

    this->hints.emplace_back(pos, posArg->name + ":");
    posIdx++;
  }
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
  if (!node->method || !node->args ||
      node->args->type != NodeType::ARGUMENT_LIST) {
    return;
  }
  auto args = node->method->args;
  const auto *al = static_cast<const ArgumentList *>(node->args.get());
  auto posIdx = 0;
  for (const auto &arg : al->args) {
    if (arg->type == NodeType::KEYWORD_ITEM ||
        arg->type == NodeType::ERROR_NODE) {
      continue;
    }
    const auto *posArg = node->method->posArg(posIdx);
    if (!posArg) {
      break;
    }
    auto pos = LSPPosition(arg->location.startLine, arg->location.startColumn);

    this->hints.emplace_back(pos, posArg->name + ":");
    posIdx++;
  }
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

void InlayHintVisitor::makeHint(const Node *node) {
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
    const auto *asList = dynamic_cast<List *>(type.get());
    if (asList) {
      if (depth >= 1) {
        strs.emplace_back("list(...)");
      } else {
        strs.push_back(
            std::format("list({})", prettify(asList->types, depth + 1)));
      }
      continue;
    }
    const auto *asDict = dynamic_cast<Dict *>(type.get());
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
  if (this->removeDefaultTypesInInlayHints && depth == 0 && strs.size() > 3) {
    std::set<std::string> const asSet{strs.begin(), strs.end()};
    if (asSet.contains("list(any)") && asSet.contains("dict(any)") &&
        asSet.contains("any")) {
      strs.erase(std::ranges::find(strs, "any"));
      strs.erase(std::ranges::find(strs, "list(any)"));
      strs.erase(std::ranges::find(strs, "dict(any)"));
    }
  }
  return joinStrings(strs, '|');
}
