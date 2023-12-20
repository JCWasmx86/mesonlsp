#include "typeanalyzer.hpp"

#include "function.hpp"
#include "log.hpp"
#include "mesonmetadata.hpp"
#include "node.hpp"
#include "partialinterpreter.hpp"
#include "type.hpp"
#include "typenamespace.hpp"
#include "utils.hpp"

#include <algorithm>
#include <cctype>
#include <filesystem>
#include <format>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <string>
#include <utility>
#include <vector>

#define TYPE_STRING_LENGTH 12
static Logger LOG("analyze::typeanalyzer"); // NOLINT

static std::vector<std::shared_ptr<Type>>
dedup(const TypeNamespace &ns, std::vector<std::shared_ptr<Type>> types);
static bool isSnakeCase(const std::string &str);
static bool isShoutingSnakeCase(const std::string &str);
static bool isType(const std::shared_ptr<Type> &type, const std::string &name);
static bool sameType(std::shared_ptr<Type> &a, std::shared_ptr<Type> &b,
                     const std::string &name);

void TypeAnalyzer::applyToStack(std::string name,
                                std::vector<std::shared_ptr<Type>> types) {
  if (this->stack.empty()) {
    return;
  }
  if (this->scope.variables.contains(name)) {
    auto orVCount = this->overriddenVariables.size() - 1;
    auto atIdx = this->overriddenVariables[orVCount];
    auto vars = this->scope.variables[name];
    if (atIdx.contains(name)) {
      atIdx[name].insert(atIdx[name].begin(), vars.begin(), vars.end());
    } else {
      atIdx[name] = vars;
    }
  }
  auto ssc = this->stack.size() - 1;
  if (this->stack[ssc].contains(name)) {
    auto old = this->stack[ssc][name];
    old.insert(old.end(), types.begin(), types.end());
  } else {
    this->stack[ssc][name] = types;
  }
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

void TypeAnalyzer::extractVoidAssignment(AssignmentStatement *node) const {
  std::string name;
  auto *fe = dynamic_cast<FunctionExpression *>(node->rhs.get());
  if (fe && fe->function) {
    name = fe->function->id();
  } else {
    auto *me = dynamic_cast<MethodExpression *>(node->rhs.get());
    if (me && me->method) {
      name = me->method->id();
    }
  }
  if (!name.starts_with("install_")) {
    this->metadata->registerDiagnostic(
        node->lhs.get(),
        Diagnostic(Severity::Error, node->lhs.get(), "Can't assign from void"));
  }
}

void TypeAnalyzer::checkIdentifier(IdExpression *node) const {
  if (this->analysisOptions.disableNameLinting) {
    return;
  }
  if (isSnakeCase(node->id) || isShoutingSnakeCase(node->id)) {
    return;
  }
  this->metadata->registerDiagnostic(
      node, Diagnostic(Severity::Warning, node, "Expected snake case"));
}

void TypeAnalyzer::evaluatePureAssignment(AssignmentStatement *node,
                                          IdExpression *lhsIdExpr) {
  auto arr = node->rhs->types;
  if (arr.empty()) {
    auto *arrLit = dynamic_cast<ArrayLiteral *>(node->rhs.get());
    if (arrLit && arrLit->args.empty()) {
      arr = {std::make_shared<List>(std::vector<std::shared_ptr<Type>>{})};
    }
    auto *dictLit = dynamic_cast<DictionaryLiteral *>(node->rhs.get());
    if (dictLit && dictLit->values.empty()) {
      arr = {std::make_shared<Dict>(std::vector<std::shared_ptr<Type>>{})};
    }
  }
  auto assignmentName = lhsIdExpr->id;
  if (assignmentName == "meson" || assignmentName == "build_machine" ||
      assignmentName == "target_machine" || assignmentName == "host_machine") {
    this->metadata->registerDiagnostic(
        lhsIdExpr,
        Diagnostic(Severity::Error, lhsIdExpr,
                   "Attempted to re-assign to existing, read-only variable"));
    return;
  }
  lhsIdExpr->types = arr;
  this->checkIdentifier(lhsIdExpr);
  this->applyToStack(lhsIdExpr->id, arr);
  this->scope.variables[lhsIdExpr->id] = arr;
  this->registerNeedForUse(lhsIdExpr);
}

void TypeAnalyzer::registerNeedForUse(IdExpression *node) {
  this->variablesNeedingUse.back().emplace_back(node);
}

std::optional<std::shared_ptr<Type>>
TypeAnalyzer::evalPlusEquals(std::shared_ptr<Type> l, std::shared_ptr<Type> r) {
  if (dynamic_cast<IntType *>(l.get()) && dynamic_cast<IntType *>(r.get())) {
    return this->ns.intType;
  }
  if (dynamic_cast<Str *>(l.get()) && dynamic_cast<Str *>(r.get())) {
    return this->ns.strType;
  }
  auto *ll = dynamic_cast<List *>(l.get());
  if (ll) {
    auto *lr = dynamic_cast<List *>(r.get());
    auto newTypes = ll->types;
    if (lr) {
      auto rTypes = lr->types;
      newTypes.insert(newTypes.end(), rTypes.begin(), rTypes.end());
    } else {
      newTypes.emplace_back(r);
    }
    return std::make_shared<List>(dedup(this->ns, newTypes));
  }
  auto *dl = dynamic_cast<Dict *>(l.get());
  if (dl) {
    auto *dr = dynamic_cast<Dict *>(r.get());
    auto newTypes = dl->types;
    if (dr) {
      auto rTypes = dr->types;
      newTypes.insert(newTypes.end(), rTypes.begin(), rTypes.end());
    } else {
      newTypes.emplace_back(r);
    }
    return std::make_shared<Dict>(dedup(this->ns, newTypes));
  }
  return std::nullopt;
}

void TypeAnalyzer::evalAssignmentTypes(
    std::shared_ptr<Type> l, std::shared_ptr<Type> r, AssignmentOperator op,
    std::vector<std::shared_ptr<Type>> *newTypes) {
  switch (op) {
  case DivEquals:
    if (dynamic_cast<IntType *>(l.get()) && dynamic_cast<IntType *>(r.get())) {
      newTypes->emplace_back(this->ns.intType);
    }
    if (dynamic_cast<Str *>(l.get()) && dynamic_cast<Str *>(r.get())) {
      newTypes->emplace_back(this->ns.strType);
    }
    break;
  case MinusEquals:
  case ModEquals:
  case MulEquals:
    if (dynamic_cast<IntType *>(l.get()) && dynamic_cast<IntType *>(r.get())) {
      newTypes->emplace_back(this->ns.intType);
    }
    break;
  case PlusEquals: {
    auto type = this->evalPlusEquals(l, r);
    if (type.has_value()) {
      newTypes->emplace_back(type->get());
    }
    break;
  }
  default:
    break;
  }
}

std::vector<std::shared_ptr<Type>>
TypeAnalyzer::evalAssignment(AssignmentOperator op,
                             std::vector<std::shared_ptr<Type>> lhs,
                             std::vector<std::shared_ptr<Type>> rhs) {
  std::vector<std::shared_ptr<Type>> ret;
  for (auto l : lhs) {
    for (auto r : rhs) {
      this->evalAssignmentTypes(l, r, op, &ret);
    }
  }
  return ret;
}

void TypeAnalyzer::evaluateFullAssignment(AssignmentStatement *node,
                                          IdExpression *lhsIdExpr) {
  if (node->op == AssignmentOperator::Equals) {
    this->evaluatePureAssignment(node, lhsIdExpr);
    return;
  }
  auto newTypes =
      dedup(this->ns,
            this->evalAssignment(node->op, node->lhs->types, node->rhs->types));
  lhsIdExpr->types = newTypes;
  this->applyToStack(lhsIdExpr->id, newTypes);
  this->scope.variables[lhsIdExpr->id] = newTypes;
}

void TypeAnalyzer::visitAssignmentStatement(AssignmentStatement *node) {
  node->visitChildren(this);
  auto *idExpr = dynamic_cast<IdExpression *>(node->lhs.get());
  if (!idExpr) {
    this->metadata->registerDiagnostic(
        node->lhs.get(), Diagnostic(Severity::Error, node->lhs.get(),
                                    "Can only assign to variables"));
    return;
  }
  if (node->op == AssignmentOpOther) {
    this->metadata->registerDiagnostic(
        node->lhs.get(), Diagnostic(Severity::Error, node->lhs.get(),
                                    "Unknown assignment operator"));
    return;
  }
  auto rhsTypes = node->rhs->types;
  if (rhsTypes.empty() &&
      (dynamic_cast<FunctionExpression *>(node->rhs.get()) ||
       dynamic_cast<MethodExpression *>(node->rhs.get()))) {
    this->extractVoidAssignment(node);
    return;
  }
  this->evaluateFullAssignment(node, idExpr);
}

bool TypeAnalyzer::isSpecial(std::vector<std::shared_ptr<Type>> &types) {
  if (types.size() != 3) {
    return false;
  }
  auto counter = 0;
  for (const auto &type : types) {
    if (dynamic_cast<Any *>(type.get())) {
      counter++;
      continue;
    }
    auto *asList = dynamic_cast<List *>(type.get());
    if (asList && asList->types.size() == 1 &&
        dynamic_cast<Any *>(asList->types[0].get())) {
      counter++;
      continue;
    }
    auto *asDict = dynamic_cast<Dict *>(type.get());
    if (asDict && asDict->types.size() == 1 &&
        dynamic_cast<Any *>(asDict->types[0].get())) {
      counter++;
      continue;
    }
    return false;
  }
  return counter == 3;
}

std::vector<std::shared_ptr<Type>> TypeAnalyzer::evalBinaryExpression(
    BinaryOperator op, std::vector<std::shared_ptr<Type>> lhs,
    std::vector<std::shared_ptr<Type>> rhs, unsigned int *numErrors) {
  std::vector<std::shared_ptr<Type>> newTypes;
  for (auto lType : lhs) {
    for (auto rType : rhs) {
      if (rType->name == "any" && lType->name == "any") {
        ++*numErrors;
        continue;
      }
      switch (op) {
      case And:
      case Or:
        if (sameType(lType, rType, "bool")) {
          newTypes.emplace_back(this->ns.boolType);
        } else {
          ++*numErrors;
        }
        break;
      case Div:
        if (sameType(lType, rType, "int")) {
          newTypes.emplace_back(this->ns.intType);
        } else if (sameType(lType, rType, "str")) {
          newTypes.emplace_back(this->ns.strType);
        } else {
          ++*numErrors;
        }
        break;
      case EqualsEquals:
      case NotEquals:
        if (sameType(lType, rType, "int")) {
          newTypes.emplace_back(this->ns.boolType);
        } else if (sameType(lType, rType, "str")) {
          newTypes.emplace_back(this->ns.boolType);
        } else if (sameType(lType, rType, "bool")) {
          newTypes.emplace_back(this->ns.boolType);
        } else if (sameType(lType, rType, "dict")) {
          newTypes.emplace_back(this->ns.boolType);
        } else if (sameType(lType, rType, "list")) {
          newTypes.emplace_back(this->ns.boolType);
        } else if (dynamic_cast<AbstractObject *>(lType.get()) &&
                   lType->name == rType->name) {
          newTypes.emplace_back(this->ns.boolType);
        } else {
          ++*numErrors;
        }
        break;
      case Ge:
      case Gt:
      case Le:
      case Lt:
        if (sameType(lType, rType, "int") || sameType(lType, rType, "str")) {
          newTypes.emplace_back(this->ns.boolType);
        } else {
          ++*numErrors;
        }
        break;
      case In:
      case NotIn:
        newTypes.emplace_back(this->ns.boolType);
        break;
      case Minus:
      case Modulo:
      case Mul:
        if (sameType(lType, rType, "int")) {
          newTypes.emplace_back(this->ns.boolType);
        } else {
          ++*numErrors;
        }
        break;
      case Plus: {
        if (sameType(lType, rType, "int") || sameType(lType, rType, "str")) {
          newTypes.emplace_back(this->ns.types.at(lType->name));
          break;
        }
        auto *list1 = dynamic_cast<List *>(lType.get());
        auto *list2 = dynamic_cast<List *>(rType.get());
        if (list1) {
          auto types = list1->types;
          if (list2) {
            types.insert(types.end(), list2->types.begin(), list2->types.end());
          } else {
            types.push_back(rType);
          }
          newTypes.emplace_back(std::make_shared<List>(types));
          break;
        }
        auto *dict1 = dynamic_cast<Dict *>(lType.get());
        auto *dict2 = dynamic_cast<Dict *>(rType.get());
        if (dict1) {
          auto types = dict1->types;
          if (dict2) {
            types.insert(types.end(), dict2->types.begin(), dict2->types.end());
          } else {
            types.push_back(rType);
          }
          newTypes.emplace_back(std::make_shared<Dict>(types));
          break;
        }
        ++*numErrors;
        break;
      }
      case BinOpOther:
      default:
        LOG.error("Whoops???");
        ++*numErrors;
        break;
      }
    }
  }
  if (*numErrors == lhs.size() * rhs.size()) {
    return lhs;
  }
  return newTypes;
}

void TypeAnalyzer::visitBinaryExpression(BinaryExpression *node) {
  node->visitChildren(this);
  if (node->op == BinaryOperator::BinOpOther) {
    auto types = node->lhs->types;
    types.insert(types.end(), node->rhs->types.begin(), node->rhs->types.end());
    node->types = types;
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::Error, node, "Unknown operator"));
    return;
  }
  auto nErrors = 0U;
  auto newTypes = this->evalBinaryExpression(node->op, node->lhs->types,
                                             node->rhs->types, &nErrors);
  auto nTimes = node->lhs->types.size() * node->rhs->types.size();
  if (nTimes != 0 && nErrors == nTimes && (!node->lhs->types.empty()) &&
      (!node->rhs->types.empty()) && !this->isSpecial(node->lhs->types) &&
      !this->isSpecial(node->rhs->types)) {
    auto lTypes = joinTypes(node->lhs->types);
    auto rTypes = joinTypes(node->lhs->types);
    auto msg = std::format("Unable to apply operator {} to types {} and {}",
                           enum2String(node->op), lTypes, rTypes);
    this->metadata->registerDiagnostic(node,
                                       Diagnostic(Severity::Error, node, msg));
  }
  node->types = dedup(this->ns, newTypes);
  auto parent = node->parent;
  if (dynamic_cast<AssignmentStatement *>(parent) ||
      dynamic_cast<SelectionStatement *>(parent)) {
    auto *me = dynamic_cast<MethodExpression *>(node->lhs.get());
    auto *sl = dynamic_cast<StringLiteral *>(node->rhs.get());
    if (me && sl) {
      this->checkIfSpecialComparison(me, sl);
      return;
    }
    me = dynamic_cast<MethodExpression *>(node->rhs.get());
    sl = dynamic_cast<StringLiteral *>(node->lhs.get());
    if (me && sl) {
      this->checkIfSpecialComparison(me, sl);
      return;
    }
  }
}

void TypeAnalyzer::checkIfSpecialComparison(MethodExpression *me,
                                            StringLiteral *sl) {
  // TODO
}

void TypeAnalyzer::visitBooleanLiteral(BooleanLiteral *node) {
  node->visitChildren(this);
  node->types.emplace_back(this->ns.boolType);
}

void TypeAnalyzer::checkProjectCall(BuildDefinition *node) {
  if (this->sourceFileStack.size() != 1) {
    return;
  }
  if (node->stmts.empty()) {
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::Error, node,
                         "Missing project() call at top of file"));
    return;
  }
  auto first = node->stmts[0];
  auto *asCall = dynamic_cast<FunctionExpression *>(first.get());
  if (asCall == nullptr || asCall->functionName() != "project") {
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::Error, node,
                         "Missing project() call at top of file"));
    return;
  }
  auto alNode = asCall->args;
  if (!alNode) {
    return;
  }
  auto *al = dynamic_cast<ArgumentList *>(alNode.get());
  if (!al) {
    return;
  }
  auto mesonVersionKwarg = al->getKwarg("meson_version");
  if (!mesonVersionKwarg) {
    return;
  }
  auto *mesonVersionSL =
      dynamic_cast<StringLiteral *>(mesonVersionKwarg->get());
  if (!mesonVersionSL) {
    return;
  }
  LOG.info(std::format("Meson version = {}", mesonVersionSL->id));
}

bool TypeAnalyzer::isDead(const std::shared_ptr<Node> &node) {
  auto *asFuncExpr = dynamic_cast<FunctionExpression *>(node.get());
  if (!asFuncExpr) {
    return false;
  }
  auto name = asFuncExpr->functionName();
  return name == "error" || name == "subdir_done";
}

void TypeAnalyzer::applyDead(std::shared_ptr<Node> &lastAlive,
                             std::shared_ptr<Node> &firstDead,
                             std::shared_ptr<Node> &lastDead) const {
  if (!lastAlive || !firstDead || !lastDead) {
    return;
  }
  this->metadata->registerDiagnostic(
      firstDead.get(), Diagnostic(Severity::Warning, firstDead.get(),
                                  lastDead.get(), "Dead code"));
}

void TypeAnalyzer::checkDeadNodes(BuildDefinition *node) {
  std::shared_ptr<Node> lastAlive = nullptr;
  std::shared_ptr<Node> firstDead = nullptr;
  std::shared_ptr<Node> lastDead = nullptr;
  for (auto b : node->stmts) {
    if (!lastAlive) {
      if (this->isDead(b)) {
        lastAlive = b;
      }
    } else {
      if (firstDead) {
        firstDead = b;
        lastDead = b;
      } else {
        lastDead = b;
      }
    }
  }
  this->applyDead(lastAlive, firstDead, lastDead);
}

void TypeAnalyzer::checkUnusedVariables() {
  auto needingUse = this->variablesNeedingUse.back();
  this->variablesNeedingUse.pop_back();
  if (!this->variablesNeedingUse.empty()) {
    auto toAppend = this->variablesNeedingUse.back();
    toAppend.insert(toAppend.end(), needingUse.begin(), needingUse.end());
    return;
  }
  for (auto *n : needingUse) {
    auto *ass = dynamic_cast<AssignmentStatement *>(n->parent);
    if (!ass) {
      continue;
    }
    auto *rhs = dynamic_cast<FunctionExpression *>(ass->rhs.get());
    if (!rhs) {
      continue;
    }
    auto fnid = rhs->functionName();
    if (fnid == "declare_dependency") {
      continue;
    }
    this->metadata->registerDiagnostic(
        n, Diagnostic(Severity::Warning, n, "Unused assignment"));
  }
}

void TypeAnalyzer::visitBuildDefinition(BuildDefinition *node) {
  this->variablesNeedingUse.emplace_back();
  this->sourceFileStack.push_back(node->file->file);
  this->tree->ownedFiles.insert(node->file->file);
  this->checkProjectCall(node);
  node->visitChildren(this);
  this->checkDeadNodes(node);
  this->checkUnusedVariables();
  this->sourceFileStack.pop_back();
}

void TypeAnalyzer::visitConditionalExpression(ConditionalExpression *node) {
  node->visitChildren(this);
  std::vector<std::shared_ptr<Type>> types(node->ifTrue->types);
  types.insert(types.end(), node->ifFalse->types.begin(),
               node->ifFalse->types.end());
  for (const auto &type : node->condition->types) {
    if (dynamic_cast<Any *>(type.get())) {
      return;
    }
    if (dynamic_cast<BoolType *>(type.get())) {
      return;
    }
    if (dynamic_cast<Disabler *>(type.get())) {
      return;
    }
  }
  this->metadata->registerDiagnostic(
      node, Diagnostic(Severity::Error, node,
                       "Condition is not bool: " +
                           joinTypes(node->condition->types)));
}

void TypeAnalyzer::checkDuplicateNodeKeys(DictionaryLiteral *node) {
  std::set<std::string> seenKeys;
  for (const auto &keyV : node->values) {
    auto *asKVI = dynamic_cast<KeyValueItem *>(keyV.get());
    if (!asKVI) {
      continue;
    }
    auto *keyNode = dynamic_cast<StringLiteral *>(asKVI->key.get());
    if (!keyNode) {
      continue;
    }
    auto keyName = keyNode->id;
    if (!seenKeys.contains(keyName)) {
      seenKeys.insert(keyName);
      continue;
    }
    this->metadata->registerDiagnostic(
        keyNode, Diagnostic(Severity::Warning, keyNode,
                            std::format("Duplicate key \"{}\"", keyName)));
  }
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
  this->checkDuplicateNodeKeys(node);
}

void TypeAnalyzer::setFunctionCallTypes(FunctionExpression *node,
                                        std::shared_ptr<Function> fn) {
  auto name = fn->name;
  if (name == "subproject") {
    // TODO
    return;
  }
  if (name == "get_option") {
    // TODO
    return;
  }
  if (name == "get_variable") {
    // TODO
    return;
  }
}

void TypeAnalyzer::specialFunctionCallHandling(FunctionExpression *node,
                                               std::shared_ptr<Function> fn) {
  auto name = fn->name;
  if (name != "subproject") {
    // TODO
    return;
  }
}

void TypeAnalyzer::checkCall(FunctionExpression *node) {}

void TypeAnalyzer::guessSetVariable(std::vector<std::shared_ptr<Node>> args,
                                    FunctionExpression *node) {
  auto guessed = ::guessSetVariable(node, this->options);
  std::set<std::string> asSet(guessed.begin(), guessed.end());
  LOG.info(std::format("Guessed values for set_variable: {} at {}:{}",
                       joinStrings(asSet, '|'), node->file->file.c_str(),
                       node->location->format()));
  for (const auto &varname : asSet) {
    auto types = args[1]->types;
    this->scope.variables[varname] = types;
    this->applyToStack(varname, types);
  }
}

void TypeAnalyzer::checkSetVariable(FunctionExpression *node,
                                    ArgumentList *al) {
  auto args = al->args;
  if (args.empty()) {
    return;
  }
  auto firstArg = args[0];
  auto *variableName = dynamic_cast<StringLiteral *>(firstArg.get());
  if (!variableName) {
    this->guessSetVariable(args, node);
  } else if (args.size() > 1) {
    auto varname = variableName->id;
    auto types = args[1]->types;
    this->scope.variables[varname] = types;
    this->applyToStack(varname, types);
    LOG.info(std::format("set_variable {} = {}", varname, joinTypes(types)));
  }
}

void TypeAnalyzer::enterSubdir(FunctionExpression *node) {
  auto *al = dynamic_cast<ArgumentList *>(node->args.get());
  if (!al || al->args.empty()) {
    return;
  }
  auto guessed = ::guessSetVariable(node, this->options);
  std::set<std::string> asSet{guessed.begin(), guessed.end()};
  auto msg = std::format("Found subdircall with dirs: {} at {}:{}",
                         joinStrings(asSet, '|'), node->file->file.c_str(),
                         node->location->format());
  if (asSet.empty()) {
    LOG.warn(msg);
  } else {
    LOG.info(msg);
  }
  for (auto dir : asSet) {
    auto dirpath = node->file->file.parent_path() / dir;
    if (!std::filesystem::exists(dirpath)) {
      if (asSet.size() == 1) {
        this->metadata->registerDiagnostic(
            node, Diagnostic(Severity::Error, node,
                             std::format("Directory does not exist: {}", dir)));
      }
      continue;
    }
    auto mesonpath = dirpath / "meson.build";
    if (!std::filesystem::exists(mesonpath)) {
      if (asSet.size() == 1) {
        this->metadata->registerDiagnostic(
            node, Diagnostic(
                      Severity::Error, node,
                      std::format("File does not exist: {}/meson.build", dir)));
      }
      continue;
    }
    auto ast = this->tree->parseFile(mesonpath);
    LOG.info(std::format("Entering {}", dir));
    ast->parent = node;
    ast->visit(this);
    LOG.info(std::format("Leaving {}", dir));
  }
}

void TypeAnalyzer::visitFunctionExpression(FunctionExpression *node) {
  node->visitChildren(this);
  auto funcName = node->functionName();
  if (funcName == INVALID_FUNCTION_NAME) {
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::Error, node,
                         std::format("Unknown function `{}`", funcName)));
    return;
  }
  auto functionOpt = this->ns.lookupFunction(funcName);
  if (!functionOpt.has_value()) {
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::Error, node,
                         std::format("Unknown function `{}`", funcName)));
    return;
  }
  auto fn = functionOpt.value();
  node->types = fn->returnTypes;
  this->setFunctionCallTypes(node, fn);
  this->specialFunctionCallHandling(node, fn);
  node->function = fn;
  auto args = node->args;
  if (!args || !dynamic_cast<ArgumentList *>(args.get())) {
    if (fn->minPosArgs == 0) {
      this->metadata->registerDiagnostic(
          node,
          Diagnostic(
              Severity::Error, node,
              std::format("Expected {} positional arguments, but got none!",
                          fn->minPosArgs)));
    }
  } else {
    this->checkCall(node);
    auto *asArgumentList = dynamic_cast<ArgumentList *>(args.get());
    if (!asArgumentList) {
      goto checkVersion;
    }
    // TODO: registerKwargs
    if (fn->name == "set_variable") {
      this->checkSetVariable(node, asArgumentList);
    }
  }
checkVersion:
  // TODO: RegisterDeprecated

  if (fn->name == "subdir") {
    this->enterSubdir(node);
  }
}

void TypeAnalyzer::visitIdExpression(IdExpression *node) {
  node->visitChildren(this);
}

void TypeAnalyzer::visitIntegerLiteral(IntegerLiteral *node) {
  node->visitChildren(this);
  node->types.emplace_back(this->ns.intType);
}

void TypeAnalyzer::analyseIterationStatementSingleIdentifier(
    IterationStatement *node) {
  auto iterTypes = node->expression->types;
  std::vector<std::shared_ptr<Type>> res;
  auto errs = 0UL;
  auto foundDict = false;
  for (const auto &iterT : iterTypes) {
    if (dynamic_cast<Range *>(iterT.get())) {
      res.emplace_back(this->ns.intType);
      continue;
    }
    auto *asList = dynamic_cast<List *>(iterT.get());
    if (asList) {
      res.insert(res.end(), asList->types.begin(), asList->types.end());
      continue;
    }
    if (dynamic_cast<Dict *>(iterT.get())) {
      foundDict = true;
    }
    errs++;
  }
  if (errs != iterTypes.size()) {
    node->ids[0]->types = dedup(this->ns, res);
  } else {
    node->ids[0]->types = {};
    this->metadata->registerDiagnostic(
        node->expression.get(),
        Diagnostic(Severity::Error, node->expression.get(),
                   foundDict ? "Iterating over a dict requires two identifiers"
                             : "Expression yields no iterable result"));
  }
  auto *id0Expr = dynamic_cast<IdExpression *>(node->ids[0].get());
  if (!id0Expr) {
    return;
  }
  this->applyToStack(id0Expr->id, node->ids[0]->types);
  this->scope.variables[id0Expr->id] = node->ids[0]->types;
  this->checkIdentifier(id0Expr);
}

void TypeAnalyzer::analyseIterationStatementTwoIdentifiers(
    IterationStatement *node) {
  auto iterTypes = node->expression->types;
  node->ids[0]->types = {this->ns.strType};
  auto found = false;
  auto foundBad = false;
  for (const auto &iterT : iterTypes) {
    auto *dict = dynamic_cast<Dict *>(iterT.get());
    foundBad |= dynamic_cast<List *>(iterT.get()) != nullptr ||
                dynamic_cast<Range *>(iterT.get()) != nullptr;
    if (!dict) {
      continue;
    }
    node->ids[1]->types = dict->types;
    found = true;
    break;
  }
  if (!found) {
    this->metadata->registerDiagnostic(
        node->expression.get(),
        Diagnostic(Severity::Error, node->expression.get(),
                   foundBad
                       ? "Iterating over a list/range requires one identifier"
                       : "Expression yields no iterable result"));
  }
  auto *id0Expr = dynamic_cast<IdExpression *>(node->ids[0].get());
  if (id0Expr) {
    this->applyToStack(id0Expr->id, node->ids[0]->types);
    this->scope.variables[id0Expr->id] = node->ids[0]->types;
    this->checkIdentifier(id0Expr);
  }
  auto *id1Expr = dynamic_cast<IdExpression *>(node->ids[1].get());
  if (id1Expr) {
    this->applyToStack(id1Expr->id, node->ids[1]->types);
    this->scope.variables[id1Expr->id] = node->ids[1]->types;
    this->checkIdentifier(id1Expr);
  }
}

void TypeAnalyzer::visitIterationStatement(IterationStatement *node) {
  node->expression->visit(this);
  for (const auto &id : node->ids) {
    id->visit(this);
  }
  auto count = node->ids.size();
  if (count == 1) {
    analyseIterationStatementSingleIdentifier(node);
  } else if (count == 2) {
    analyseIterationStatementTwoIdentifiers(node);
  } else {
    auto *fNode = node->ids[0].get();
    auto *eNode = node->ids[1].get();
    this->metadata->registerDiagnostic(
        fNode,
        Diagnostic(Severity::Error, fNode, eNode,
                   "Iteration statement expects only one or two identifiers"));
  }
  std::shared_ptr<Node> lastAlive = nullptr;
  std::shared_ptr<Node> firstDead = nullptr;
  std::shared_ptr<Node> lastDead = nullptr;
  for (auto b : node->stmts) {
    b->visit(this);
    if (!lastAlive) {
      if (this->isDead(b)) {
        lastAlive = b;
      }
    } else {
      if (firstDead) {
        firstDead = b;
        lastDead = b;
      } else {
        lastDead = b;
      }
    }
  }
  this->applyDead(lastAlive, firstDead, lastDead);
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

bool TypeAnalyzer::checkCondition(Node *condition) {
  auto appended = false;
  auto *fn = dynamic_cast<FunctionExpression *>(condition);
  if ((fn != nullptr) && fn->functionName() == "get") {
    auto *al = dynamic_cast<ArgumentList *>(fn->args.get());
    if (al && !al->args.empty()) {
      auto *testedIdentifier = dynamic_cast<StringLiteral *>(al->args[0].get());
      if (testedIdentifier) {
        this->ignoreUnknownIdentifier.emplace_back(testedIdentifier->id);
        appended = true;
      }
    }
  }
  auto foundBoolOrAny = false;
  for (const auto &type : condition->types) {
    if (dynamic_cast<Any *>(type.get()) ||
        dynamic_cast<BoolType *>(type.get()) ||
        dynamic_cast<Disabler *>(type.get())) {
      foundBoolOrAny = true;
      break;
    }
  }
  if (!foundBoolOrAny && !condition->types.empty()) {
    auto joined = joinTypes(condition->types);
    this->metadata->registerDiagnostic(
        condition, Diagnostic(Severity::Error, condition,
                              "Condition is not bool: " + joined));
  }
  return appended;
}

void TypeAnalyzer::visitSelectionStatement(SelectionStatement *node) {
  this->stack.emplace_back();
  this->overriddenVariables.emplace_back();
  std::map<std::string, std::vector<std::shared_ptr<Type>>> oldVars;
  for (auto oldVar : this->scope.variables) {
    oldVars[oldVar.first] = std::vector<std::shared_ptr<Type>>{
        oldVar.second.begin(), oldVar.second.end()};
  }
  auto idx = 0UL;
  std::vector<IdExpression *> allLeft;
  for (const auto &block : node->blocks) {
    auto appended = false;
    if (idx < node->conditions.size()) {
      auto cond = node->conditions[idx];
      cond->visit(this);
      appended = this->checkCondition(cond.get());
    }
    std::shared_ptr<Node> lastAlive = nullptr;
    std::shared_ptr<Node> firstDead = nullptr;
    std::shared_ptr<Node> lastDead = nullptr;
    this->variablesNeedingUse.emplace_back();
    for (const auto &stmt : block) {
      stmt->visit(this);
      if (!lastAlive) {
        if (this->isDead(stmt)) {
          lastAlive = stmt;
        }
      } else {
        if (firstDead) {
          firstDead = stmt;
          lastDead = stmt;
        } else {
          lastDead = stmt;
        }
      }
    }
    this->applyDead(lastAlive, firstDead, lastDead);
    if (appended) {
      this->ignoreUnknownIdentifier.pop_back();
    }
    auto lastNeedingUse = this->variablesNeedingUse.back();
    allLeft.insert(allLeft.end(), lastNeedingUse.begin(), lastNeedingUse.end());
    this->variablesNeedingUse.pop_back();
    idx++;
  }
  std::set<std::string> dedupedUnusedAssignments;
  auto toInsert = this->variablesNeedingUse.back();
  for (auto *idExpr : allLeft) {
    if (dedupedUnusedAssignments.contains(idExpr->id)) {
      continue;
    }
    dedupedUnusedAssignments.insert(idExpr->id);
    toInsert.emplace_back(idExpr);
  }
  auto types = this->stack.back();
  this->stack.pop_back();
  // If: 1 c, 1 b
  // If,else if: 2c, 2b
  // if, else if, else, 2c, 3b
  for (auto pair : types) {
    // This leaks some overwritten types. This can't be solved
    // without costly static analysis
    // x = 'Foo'
    // if bar
    //   x = 2
    // else
    //   x = true
    // endif
    // x is now str|int|bool instead of int|bool
    auto key = pair.first;
    auto arr = this->scope.variables.contains(pair.first)
                   ? this->scope.variables[pair.first]
                   : std::vector<std::shared_ptr<Type>>{};
    arr.insert(arr.end(), pair.second.begin(), pair.second.end());
    if (node->conditions.size() == node->blocks.size()) {
      if (oldVars.contains(pair.first)) {
        arr.insert(arr.end(), oldVars[pair.first].begin(),
                   oldVars[pair.first].end());
      }
    }
    this->scope.variables[pair.first] = dedup(this->ns, arr);
  }
  this->overriddenVariables.pop_back();
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
      newTypes.emplace_back(this->ns.types.at("custom_idx"));
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
    this->metadata->registerDiagnostic(
        node, Diagnostic(Severity::Error, node, "Bad unary operator"));
    break;
  }
}

void TypeAnalyzer::visitErrorNode(ErrorNode *node) {
  node->visitChildren(this);
  this->metadata->registerDiagnostic(
      node, Diagnostic(Severity::Error, node, node->message));
}

void TypeAnalyzer::visitBreakNode(BreakNode *node) {
  this->checkIfInLoop(node, "break");
}

void TypeAnalyzer::visitContinueNode(ContinueNode *node) {
  this->checkIfInLoop(node, "continue");
}

void TypeAnalyzer::checkIfInLoop(Node *node, std::string str) const {
  auto *parent = node->parent;
  while (parent) {
    if (dynamic_cast<IterationStatement *>(parent)) {
      return;
    }
    if (dynamic_cast<BuildDefinition *>(parent)) {
      break;
    }
    parent = parent->parent;
  }
  this->metadata->registerDiagnostic(
      node,
      Diagnostic(
          Severity::Error, node,
          std::format("{} statements are only allowed inside loops", str)));
}

static std::vector<std::shared_ptr<Type>>
dedup(const TypeNamespace &ns, std::vector<std::shared_ptr<Type>> types) {
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
    ret.emplace_back(ns.types.at("any"));
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
  return ret;
}

std::string joinTypes(std::vector<std::shared_ptr<Type>> &types) {
  std::vector<std::string> vector;
  vector.reserve(types.size());
  for (const auto &type : types) {
    vector.push_back(type->toString());
  }
  std::sort(vector.begin(), vector.end());
  std::string ret;
  ret.reserve(vector.size() * TYPE_STRING_LENGTH);
  for (size_t i = 0; i < vector.size(); i++) {
    ret.append(vector[i]);
    if (i != vector.size() - 1) {
      ret.append("|");
    }
  }
  return ret;
}

static bool isSnakeCase(const std::string &str) {
  for (auto chr : str) {
    if (std::isupper(chr) != 0 && chr != '_') {
      return false;
    }
  }
  return true;
}

static bool isShoutingSnakeCase(const std::string &str) {
  for (auto chr : str) {
    if (std::islower(chr) != 0 && chr != '_') {
      return false;
    }
  }
  return true;
}

static bool isType(const std::shared_ptr<Type> &type, const std::string &name) {
  return type->name == name || type->name == "any";
}

static bool sameType(std::shared_ptr<Type> &a, std::shared_ptr<Type> &b,
                     const std::string &name) {
  return isType(a, name) && isType(b, name);
}
