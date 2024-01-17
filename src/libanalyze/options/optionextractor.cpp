#include "optionextractor.hpp"

#include "log.hpp"
#include "mesonoption.hpp"
#include "node.hpp"

#include <format>
#include <memory>
#include <optional>
#include <ranges>
#include <string>
#include <vector>

const static Logger LOG("analyze::optionextractor"); // NOLINT

void OptionExtractor::visitArgumentList(ArgumentList *node) {
  node->visitChildren(this);
}

void OptionExtractor::visitArrayLiteral(ArrayLiteral *node) {
  node->visitChildren(this);
}

void OptionExtractor::visitAssignmentStatement(AssignmentStatement *node) {
  node->visitChildren(this);
}

void OptionExtractor::visitBinaryExpression(BinaryExpression *node) {
  node->visitChildren(this);
}

void OptionExtractor::visitBooleanLiteral(BooleanLiteral *node) {
  node->visitChildren(this);
}

void OptionExtractor::visitBuildDefinition(BuildDefinition *node) {
  node->visitChildren(this);
}

void OptionExtractor::visitConditionalExpression(ConditionalExpression *node) {
  node->visitChildren(this);
}

void OptionExtractor::visitDictionaryLiteral(DictionaryLiteral *node) {
  node->visitChildren(this);
}

void OptionExtractor::visitFunctionExpression(FunctionExpression *node) {
  node->visitChildren(this);
  if (node->functionName() != "option") {
    return;
  }
  auto *al = dynamic_cast<ArgumentList *>(node->args.get());
  if (al == nullptr) {
    return;
  }
  auto firstArg = al->getPositionalArg(0);
  if (!firstArg.has_value()) {
    return;
  }
  auto *nameNode = dynamic_cast<StringLiteral *>(firstArg->get());
  if (nameNode == nullptr) {
    return;
  }
  const auto &optionName = nameNode->id;
  auto typeKwarg = al->getKwarg("type");
  if (!typeKwarg.has_value()) {
    return;
  }
  auto *typeKwargAsStr = dynamic_cast<StringLiteral *>(typeKwarg->get());
  if (typeKwargAsStr == nullptr) {
    return;
  }
  const auto &optionType = typeKwargAsStr->id;
  LOG.info(
      std::format("Found option {} with type '{}'", optionName, optionType));
  std::optional<std::string> description = std::nullopt;
  auto descriptionKwarg = al->getKwarg("description");
  if (descriptionKwarg.has_value()) {
    auto *descriptionAsStringLiteral =
        dynamic_cast<StringLiteral *>(descriptionKwarg->get());
    if (descriptionAsStringLiteral == nullptr) {
      goto cont; // Goto to reduce indentations
    }
    description = descriptionAsStringLiteral->id;
  }
cont:
  bool deprecated = false;
  auto deprecatedKwarg = al->getKwarg("deprecated");
  if (deprecatedKwarg) {
    auto *deprecatedKwargAsBoolLiteral =
        dynamic_cast<BooleanLiteral *>(deprecatedKwarg->get());
    if (deprecatedKwargAsBoolLiteral == nullptr) {
      goto cont2;
    }
    deprecated = deprecatedKwargAsBoolLiteral->value;
  }
cont2:
  std::vector<std::string> choices;
  auto choicesKwarg = al->getKwarg("choices");
  if (choicesKwarg) {
    auto *asArrayKwarg = dynamic_cast<ArrayLiteral *>(choicesKwarg->get());
    if (asArrayKwarg == nullptr) {
      goto cont3;
    }
    auto asStringLiterals =
        asArrayKwarg->args |
        std::ranges::views::filter([](std::shared_ptr<Node> &node) {
          return dynamic_cast<StringLiteral *>(node.get()) != nullptr;
        });
    for (const auto &sl : asStringLiterals) {
      choices.push_back(dynamic_cast<StringLiteral *>(sl.get())->id);
    }
  }
cont3:
  if (optionType == "string") {
    this->options.push_back(
        std::make_shared<StringOption>(optionName, description, deprecated));
  } else if (optionType == "integer") {
    this->options.push_back(
        std::make_shared<IntOption>(optionName, description, deprecated));
  } else if (optionType == "boolean") {
    this->options.push_back(
        std::make_shared<BoolOption>(optionName, description, deprecated));
  } else if (optionType == "feature") {
    this->options.push_back(
        std::make_shared<FeatureOption>(optionName, description, deprecated));
  } else if (optionType == "array") {
    this->options.push_back(std::make_shared<ArrayOption>(
        optionName, choices, description, deprecated));
  } else if (optionType == "combo") {
    this->options.push_back(std::make_shared<ComboOption>(
        optionName, choices, description, deprecated));
  } else {
    LOG.warn(std::format("Unknown option type: {}", optionType));
  }
}

void OptionExtractor::visitIdExpression(IdExpression *node) {
  node->visitChildren(this);
}

void OptionExtractor::visitIntegerLiteral(IntegerLiteral *node) {
  node->visitChildren(this);
}

void OptionExtractor::visitIterationStatement(IterationStatement *node) {
  node->visitChildren(this);
}

void OptionExtractor::visitKeyValueItem(KeyValueItem *node) {
  node->visitChildren(this);
}

void OptionExtractor::visitKeywordItem(KeywordItem *node) {
  node->visitChildren(this);
}

void OptionExtractor::visitMethodExpression(MethodExpression *node) {
  node->visitChildren(this);
}

void OptionExtractor::visitSelectionStatement(SelectionStatement *node) {
  node->visitChildren(this);
}

void OptionExtractor::visitStringLiteral(StringLiteral *node) {
  node->visitChildren(this);
}

void OptionExtractor::visitSubscriptExpression(SubscriptExpression *node) {
  node->visitChildren(this);
}

void OptionExtractor::visitUnaryExpression(UnaryExpression *node) {
  node->visitChildren(this);
}

void OptionExtractor::visitErrorNode(ErrorNode *node) {
  node->visitChildren(this);
}

void OptionExtractor::visitBreakNode(BreakNode *node) {
  node->visitChildren(this);
}

void OptionExtractor::visitContinueNode(ContinueNode *node) {
  node->visitChildren(this);
}
