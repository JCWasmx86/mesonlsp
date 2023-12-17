#include "typeanalyzer.hpp"

#include "log.hpp"
#include "node.hpp"
#include "type.hpp"
#include "typenamespace.hpp"

#include <format>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

static Logger LOG("analyze::typeanalyzer"); // NOLINT

static std::vector<std::shared_ptr<Type>>
dedup(TypeNamespace &ns, std::vector<std::shared_ptr<Type>> types) {
  if (types.size() <= 1) {
    return types;
  }
  std::vector<std::shared_ptr<Type>> listtypes;
  std::vector<std::shared_ptr<Type>> dicttypes;
  std::set<std::string> subprojectNames;
  auto hasAny = false;
  auto hasBool = false;
  auto hasInt = false;
  auto hasStr = false;
  std::map<std::string, std::shared_ptr<Type>> objs;
  auto gotList = false;
  auto gotDict = false;
  auto gotSubproject = false;
  for (const auto &type : types) {
    auto *asRaw = type.get();
    if (dynamic_cast<Any *>(asRaw) != nullptr) {
      hasAny = true;
      continue;
    }
    if (dynamic_cast<BoolType *>(asRaw) != nullptr) {
      hasBool = true;
      continue;
    }
    if (dynamic_cast<IntType *>(asRaw) != nullptr) {
      hasInt = true;
      continue;
    }
    if (dynamic_cast<Str *>(asRaw) != nullptr) {
      hasStr = true;
      continue;
    }
    auto *asDict = dynamic_cast<Dict *>(asRaw);
    if (asDict != nullptr) {
      for (const auto &t : asDict->types) {
        dicttypes.emplace_back(t);
      }
      gotDict = true;
      continue;
    }
    auto *asList = dynamic_cast<List *>(asRaw);
    if (asList != nullptr) {
      for (const auto &t : asList->types) {
        listtypes.emplace_back(t);
      }
      gotList = true;
      continue;
    }
    auto *asSubproject = dynamic_cast<Subproject *>(asRaw);
    if (asSubproject != nullptr) {
      for (const auto &name : asSubproject->names) {
        subprojectNames.insert(name);
      }
      gotSubproject = true;
      continue;
    }
    objs[type->name] = type;
  }
  std::vector<std::shared_ptr<Type>> ret;
  if ((!listtypes.empty()) || gotList) {
    ret.emplace_back(std::make_shared<List>(dedup(ns, listtypes)));
  }
  if ((!dicttypes.empty()) || gotDict) {
    ret.emplace_back(std::make_shared<Dict>(dedup(ns, dicttypes)));
  }
  if ((!subprojectNames.empty()) || gotSubproject) {
    ret.emplace_back(std::make_shared<Subproject>(std::vector<std::string>(
        subprojectNames.begin(), subprojectNames.end())));
  }
  if (hasAny) {
    ret.emplace_back(ns.types["any"]);
  }
  if (hasBool) {
    ret.emplace_back(ns.boolType);
  }
  if (hasInt) {
    ret.emplace_back(ns.intType);
  }
  if (hasStr) {
    ret.emplace_back(ns.strType);
  }
  for (const auto &obj : objs) {
    ret.emplace_back(obj.second);
  }
  LOG.info(std::format("Reduced from {} to {}", types.size(), ret.size()));
  return ret;
}

void TypeAnalyzer::visitArgumentList(ArgumentList *node) {
  node->visitChildren(this);
}

void TypeAnalyzer::visitArrayLiteral(ArrayLiteral *node) {
  node->visitChildren(this);
  std::vector<std::shared_ptr<Type>> types;
  for (const auto &arg : node->args) {
    for (const auto &type : arg->types) {
      types.emplace_back(type);
    }
  }
  node->types = std::vector<std::shared_ptr<Type>>{
      std::make_shared<List>(dedup(this->ns, types))};
}

void TypeAnalyzer::visitAssignmentStatement(AssignmentStatement *node) {
  node->visitChildren(this);
}

void TypeAnalyzer::visitBinaryExpression(BinaryExpression *node) {
  node->visitChildren(this);
}

void TypeAnalyzer::visitBooleanLiteral(BooleanLiteral *node) {
  node->visitChildren(this);
  node->types.emplace_back(this->ns.boolType);
}

void TypeAnalyzer::visitBuildDefinition(BuildDefinition *node) {
  node->visitChildren(this);
}

void TypeAnalyzer::visitConditionalExpression(ConditionalExpression *node) {
  node->visitChildren(this);
  std::vector<std::shared_ptr<Type>> types(node->ifTrue->types);
  types.insert(types.end(), node->ifFalse->types.begin(),
               node->ifFalse->types.end());
}

void TypeAnalyzer::visitDictionaryLiteral(DictionaryLiteral *node) {
  node->visitChildren(this);
  std::vector<std::shared_ptr<Type>> types;
  for (const auto &arg : node->values) {
    for (const auto &type : arg->types) {
      types.emplace_back(type);
    }
  }
  node->types = std::vector<std::shared_ptr<Type>>{
      std::make_shared<List>(dedup(this->ns, types))};
}

void TypeAnalyzer::visitFunctionExpression(FunctionExpression *node) {
  node->visitChildren(this);
}

void TypeAnalyzer::visitIdExpression(IdExpression *node) {
  node->visitChildren(this);
}

void TypeAnalyzer::visitIntegerLiteral(IntegerLiteral *node) {
  node->visitChildren(this);
  node->types.emplace_back(this->ns.intType);
}

void TypeAnalyzer::visitIterationStatement(IterationStatement *node) {
  node->visitChildren(this);
}

void TypeAnalyzer::visitKeyValueItem(KeyValueItem *node) {
  node->visitChildren(this);
  node->types = node->value->types;
}

void TypeAnalyzer::visitKeywordItem(KeywordItem *node) {
  node->visitChildren(this);
}

void TypeAnalyzer::visitMethodExpression(MethodExpression *node) {
  node->visitChildren(this);
}

void TypeAnalyzer::visitSelectionStatement(SelectionStatement *node) {
  node->visitChildren(this);
}

void TypeAnalyzer::visitStringLiteral(StringLiteral *node) {
  node->visitChildren(this);
  node->types.push_back(this->ns.strType);
}

void TypeAnalyzer::visitSubscriptExpression(SubscriptExpression *node) {
  node->visitChildren(this);
  std::vector<std::shared_ptr<Type>> newTypes;
  for (const auto &type : node->outer->types) {
    auto *asDict = dynamic_cast<Dict *>(type.get());
    if (asDict != nullptr) {
      auto dTypes = asDict->types;
      newTypes.insert(newTypes.begin(), dTypes.begin(), dTypes.end());
      continue;
    }
    auto *asList = dynamic_cast<List *>(type.get());
    if (asList != nullptr) {
      auto lTypes = asList->types;
      newTypes.insert(newTypes.begin(), lTypes.begin(), lTypes.end());
      continue;
    }
    if (dynamic_cast<Str *>(type.get()) != nullptr) {
      newTypes.emplace_back(this->ns.strType);
      continue;
    }
    if (dynamic_cast<CustomTgt *>(type.get()) != nullptr) {
      newTypes.emplace_back(this->ns.types["custom_idx"]);
      continue;
    }
  }
  node->types = dedup(this->ns, newTypes);
}

void TypeAnalyzer::visitUnaryExpression(UnaryExpression *node) {
  node->visitChildren(this);
  switch (node->op) {
  case Not:
  case ExclamationMark:
    node->types.push_back(this->ns.boolType);
    break;
  case UnaryMinus:
    node->types.push_back(this->ns.intType);
    break;
  case UnaryOther:
  default:
    break;
  }
}

void TypeAnalyzer::visitErrorNode(ErrorNode *node) {
  node->visitChildren(this);
}

void TypeAnalyzer::visitBreakNode(BreakNode *node) {
  node->visitChildren(this);
}

void TypeAnalyzer::visitContinueNode(ContinueNode *node) {
  node->visitChildren(this);
}
