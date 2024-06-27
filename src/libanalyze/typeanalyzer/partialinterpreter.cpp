// HERE BE DRAGONS
#include "partialinterpreter.hpp"

#include "log.hpp"
#include "mesonoption.hpp"
#include "node.hpp"
#include "optionstate.hpp"
#include "polyfill.hpp"
#include "utils.hpp"

#include <algorithm>
#include <cassert>
#include <cctype>
#include <cstdint>
#include <iterator>
#include <memory>
#include <ranges>
#include <set>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

const static Logger LOG("typeanalyzer::partialinterpreter"); // NOLINT

std::vector<std::shared_ptr<InterpretNode>> allAbstractStringCombinations(
    std::vector<std::vector<std::shared_ptr<InterpretNode>>> arrays);
bool isValidMethod(const MethodExpression *me);
std::string applyMethod(const std::string &deduced, const std::string &name,
                        const std::shared_ptr<Node> &args);
bool isValidFunction(const FunctionExpression *fe);
std::vector<std::string> splitString(const std::string &str);

std::vector<std::string> guessSetVariable(FunctionExpression *fe,
                                          OptionState &opts) {
  using enum NodeType;
  if (!fe->args || fe->args->type != ARGUMENT_LIST) {
    return {};
  }
  const auto *al = static_cast<const ArgumentList *>(fe->args.get());
  if (al->args.empty()) {
    return {};
  }
  auto toCalculate = al->args[0];
  Node *parent = fe;
  while (true) {
    const auto *probableParent = parent->parent;
    if (probableParent->type == ITERATION_STATEMENT ||
        probableParent->type == SELECTION_STATEMENT ||
        probableParent->type == BUILD_DEFINITION) {
      break;
    }
    parent = parent->parent;
    assert(parent);
  }
  PartialInterpreter calc(opts);
  return calc.calculate(parent, toCalculate.get());
}

std::vector<std::string> guessSetVariable(FunctionExpression *fe,
                                          const std::string &kwargName,
                                          OptionState &opts) {
  const auto *al = dynamic_cast<const ArgumentList *>(fe->args.get());
  if (!al || al->args.empty()) {
    return {};
  }
  auto toCalculate = al->getKwarg(kwargName);
  if (!toCalculate) {
    return {};
  }
  Node *parent = fe;
  while (true) {
    const auto *probableParent = parent->parent;
    if (dynamic_cast<const IterationStatement *>(probableParent) ||
        dynamic_cast<const SelectionStatement *>(probableParent) ||
        dynamic_cast<const BuildDefinition *>(probableParent)) {
      break;
    }
    parent = parent->parent;
    assert(parent);
  }
  PartialInterpreter calc(opts);
  return calc.calculate(parent, toCalculate->get());
}

std::vector<std::string> guessGetVariableMethod(MethodExpression *me,
                                                OptionState &opts) {
  const auto *al = dynamic_cast<const ArgumentList *>(me->args.get());
  if (!al || al->args.empty()) {
    return {};
  }
  auto toCalculate = al->args[0];
  Node *parent = me;
  while (true) {
    const auto *probableParent = parent->parent;
    if (dynamic_cast<const IterationStatement *>(probableParent) ||
        dynamic_cast<const SelectionStatement *>(probableParent) ||
        dynamic_cast<const BuildDefinition *>(probableParent)) {
      break;
    }
    parent = parent->parent;
  }
  PartialInterpreter calc(opts);
  return calc.calculate(parent, toCalculate.get());
}

std::vector<std::string>
PartialInterpreter::calculate(const Node *parent, const Node *exprToCalculate) {
  return this->calculateExpression(parent, exprToCalculate);
}

std::vector<std::string>
PartialInterpreter::calculateBinaryExpression(const Node *parentExpr,
                                              const BinaryExpression *be) {
  auto lhs = this->calculateExpression(parentExpr, be->lhs.get());
  auto rhs = this->calculateExpression(parentExpr, be->rhs.get());
  std::vector<std::string> ret;
  const auto *opStr = be->op == BinaryOperator::DIV ? "/" : "";
  for (const auto &left : lhs) {
    for (const auto &right : rhs) {
      ret.emplace_back(std::format("{}{}{}", left, opStr, right));
    }
  }
  return ret;
}

std::vector<std::string>
PartialInterpreter::calculateStringFormatMethodCall(const MethodExpression *me,
                                                    const ArgumentList *al,
                                                    const Node *parentExpr) {
  auto objStrs = this->calculateExpression(parentExpr, me->obj.get());
  auto fmtStrs = this->calculateExpression(parentExpr, al->args[0].get());
  std::vector<std::string> ret;
  for (const auto &origStr : objStrs) {
    for (const auto &formatArg : fmtStrs) {
      auto copy = std::string(origStr);
      auto raw = replace(copy, "@0@", formatArg);
      ret.push_back(raw);
    }
  }
  return ret;
}

std::vector<std::string> PartialInterpreter::calculateGetMethodCall(
    const ArgumentList *al, const IdExpression *meObj, const Node *parentExpr) {
  auto nodes = this->resolveArrayOrDict(parentExpr, meObj);
  std::vector<std::string> ret;
  auto first = al->args[0];
  const auto *il = dynamic_cast<const IntegerLiteral *>(first.get());
  auto idx = il ? il->valueAsInt : (uint64_t)-1;
  const auto *sl = dynamic_cast<const StringLiteral *>(first.get());
  for (const auto &node : nodes) {
    const auto *arrLit = dynamic_cast<const ArrayLiteral *>(node->node);
    if (arrLit) {
      if (il) {
        if (idx < arrLit->args.size()) {
          const auto *slAtIdx =
              dynamic_cast<const StringLiteral *>(arrLit->args[idx].get());
          ret.emplace_back(slAtIdx->id);
        }
        continue;
      }
      if (!sl) {
        continue;
      }
      for (const auto &arrayItem : arrLit->args) {
        const auto *dict =
            dynamic_cast<const DictionaryLiteral *>(arrayItem.get());
        if (!dict) {
          continue;
        }
        for (const auto &keyValueNode : dict->values) {
          const auto *kvi =
              dynamic_cast<const KeyValueItem *>(keyValueNode.get());
          if (!kvi) {
            continue;
          }
          const auto &name = kvi->getKeyName();
          if (name != sl->id) {
            continue;
          }
          const auto *kviValue =
              dynamic_cast<const StringLiteral *>(kvi->value.get());
          if (kviValue) {
            ret.emplace_back(kviValue->id);
          }
        }
      }
      continue;
    }
    const auto *dict = dynamic_cast<const DictionaryLiteral *>(node->node);
    if (!dict || !sl) {
      continue;
    }
    for (const auto &kviNode : dict->values) {
      const auto *kvi = dynamic_cast<const KeyValueItem *>(kviNode.get());
      if (!kvi) {
        continue;
      }
      const auto &name = kvi->getKeyName();
      if (name != sl->id) {
        continue;
      }
      const auto *kviValue =
          dynamic_cast<const StringLiteral *>(kvi->value.get());
      if (kviValue) {
        ret.emplace_back(kviValue->id);
      }
    }
  }
  return ret;
}

std::vector<std::string>
PartialInterpreter::calculateIdExpression(const IdExpression *idExpr,
                                          const Node *parentExpr) {
  auto found = this->resolveArrayOrDict(parentExpr, idExpr);
  std::vector<std::string> ret;
  for (const auto &foundNode : found) {
    const auto *node = foundNode->node;
    const auto *stringNode = dynamic_cast<const StringLiteral *>(node);
    if (stringNode) {
      ret.emplace_back(stringNode->id);
      continue;
    }
    const auto *arrayNode = dynamic_cast<const ArrayNode *>(foundNode.get());
    if (!arrayNode) {
      continue;
    }
    const auto *al = dynamic_cast<const ArrayLiteral *>(node);
    if (!al) {
      continue;
    }
    for (const auto &arg : al->args) {
      const auto *sl = dynamic_cast<const StringLiteral *>(arg.get());
      if (sl) {
        ret.emplace_back(sl->id);
      }
    }
  }
  return ret;
}

void PartialInterpreter::calculateEvalSubscriptExpression(
    const std::shared_ptr<InterpretNode> &inner,
    const std::shared_ptr<InterpretNode> &outer,
    std::vector<std::string> &ret) {
  const auto *first = inner->node;
  const auto *il = dynamic_cast<const IntegerLiteral *>(first);
  auto idx = il ? il->valueAsInt : (uint64_t)-1;
  const auto *sl = dynamic_cast<const StringLiteral *>(first);
  const auto *arrLit = dynamic_cast<const ArrayLiteral *>(outer->node);
  if (arrLit) {
    if (il) {
      if (idx < arrLit->args.size()) {
        const auto *slAtIdx =
            dynamic_cast<const StringLiteral *>(arrLit->args[idx].get());
        if (slAtIdx) {
          ret.emplace_back(slAtIdx->id);
        }
      }
      return;
    }
    if (!sl) {
      return;
    }
    for (const auto &arrayItem : arrLit->args) {
      const auto *dict =
          dynamic_cast<const DictionaryLiteral *>(arrayItem.get());
      if (!dict) {
        continue;
      }
      for (const auto &keyValueNode : dict->values) {
        const auto *kvi =
            dynamic_cast<const KeyValueItem *>(keyValueNode.get());
        if (!kvi) {
          continue;
        }
        const auto &name = kvi->getKeyName();
        if (name != sl->id) {
          continue;
        }
        const auto *kviValue =
            dynamic_cast<const StringLiteral *>(kvi->value.get());
        if (kviValue) {
          ret.emplace_back(kviValue->id);
        }
      }
    }
    return;
  }
  const auto *dict = dynamic_cast<const DictionaryLiteral *>(outer->node);
  if (!dict || !sl) {
    return;
  }
  for (const auto &keyValueNode : dict->values) {
    const auto *kvi = dynamic_cast<const KeyValueItem *>(keyValueNode.get());
    if (!kvi) {
      continue;
    }
    const auto &name = kvi->getKeyName();
    if (name != sl->id) {
      continue;
    }
    const auto *kviValue =
        dynamic_cast<const StringLiteral *>(kvi->value.get());
    if (kviValue) {
      ret.emplace_back(kviValue->id);
    }
  }
}

std::vector<std::string>
PartialInterpreter::calculateSubscriptExpression(const SubscriptExpression *sse,
                                                 const Node *parentExpr) {
  auto outerNodes = this->abstractEval(parentExpr, sse->outer.get());
  auto innerNodes = this->abstractEval(parentExpr, sse->inner.get());
  std::vector<std::string> ret;
  for (const auto &outer : outerNodes) {
    for (const auto &inner : innerNodes) {
      this->calculateEvalSubscriptExpression(inner, outer, ret);
    }
    const auto *dictN = dynamic_cast<const DictionaryLiteral *>(outer->node);
    if (!dictN || !innerNodes.empty()) {
      continue;
    }
    for (const auto &keyValueNode : dictN->values) {
      const auto *kvi = dynamic_cast<const KeyValueItem *>(keyValueNode.get());
      if (!kvi) {
        continue;
      }
      const auto *sl = dynamic_cast<const StringLiteral *>(kvi->value.get());
      if (sl) {
        ret.emplace_back(sl->id);
      }
    }
  }
  return ret;
}

std::vector<std::string>
PartialInterpreter::calculateFunctionExpression(const FunctionExpression *fe,
                                                const Node *parentExpr) {
  std::set<std::string> const funcs{"join_paths", "get_option"};
  std::vector<std::string> ret;
  const auto func = fe->function;
  const auto *feId = dynamic_cast<const IdExpression *>(fe->id.get());
  if (!feId) {
    return ret;
  }
  if (!func) {
    if (!funcs.contains(feId->id)) {
      return ret;
    }
  } else {
    if (!funcs.contains(func->name)) {
      return ret;
    }
  }
  auto al = fe->args;
  if (!al) {
    return ret;
  }
  const auto *args = dynamic_cast<const ArgumentList *>(al.get());
  if (!args) {
    return ret;
  }
  if (feId->id == "get_option") {
    if (args->args.empty()) {
      return ret;
    }
    const auto *first =
        dynamic_cast<const StringLiteral *>(args->args[0].get());
    if (!first) {
      return ret;
    }
    const auto option = this->options.findOption(first->id);
    if (!option) {
      return ret;
    }
    const auto *comboOpt = dynamic_cast<const ComboOption *>(option.get());
    if (comboOpt) {
      return comboOpt->values;
    }
    const auto *arrayOpt = dynamic_cast<const ArrayOption *>(option.get());
    if (arrayOpt) {
      return arrayOpt->choices;
    }
    return ret;
  }
  std::vector<std::vector<std::shared_ptr<InterpretNode>>> items;
  for (const auto &arrayItem : args->args) {
    if (dynamic_cast<const KeywordItem *>(arrayItem.get())) {
      continue;
    }
    auto evaled = this->abstractEval(parentExpr, arrayItem.get());
    items.emplace_back(evaled);
  }
  const auto combinations = allAbstractStringCombinations(items);
  for (const auto &combo : combinations) {
    const auto *sl = dynamic_cast<const StringLiteral *>(combo->node);
    if (sl) {
      ret.emplace_back(sl->id);
    }
  }
  return ret;
}

std::vector<std::string>
PartialInterpreter::calculateExpression(const Node *parentExpr,
                                        const Node *argExpression) {
  const auto *sl = dynamic_cast<const StringLiteral *>(argExpression);
  if (sl) {
    return std::vector<std::string>{sl->id};
  }
  const auto *be = dynamic_cast<const BinaryExpression *>(argExpression);
  if (be) {
    return this->calculateBinaryExpression(parentExpr, be);
  }
  const auto *me = dynamic_cast<const MethodExpression *>(argExpression);
  if (me) {
    const auto *meId = dynamic_cast<const IdExpression *>(me->id.get());
    if (!meId) {
      return {};
    }
    if (isValidMethod(me)) {
      auto objStrs = this->calculateExpression(parentExpr, me->obj.get());
      std::vector<std::string> ret;
      ret.reserve(objStrs.size());
      for (const auto &objStr : objStrs) {
        ret.emplace_back(applyMethod(objStr, meId->id, me->args));
      }
      return ret;
    }
    if (!me->args) {
      return {};
    }
    const auto *al = dynamic_cast<const ArgumentList *>(me->args.get());
    if (!al || al->args.empty()) {
      return {};
    }
    if (meId->id == "format") {
      return this->calculateStringFormatMethodCall(me, al, parentExpr);
    }
    const auto *meObj = dynamic_cast<const IdExpression *>(me->obj.get());
    if (meId->id == "get" && meObj) {
      return this->calculateGetMethodCall(al, meObj, parentExpr);
    }
  }
  const auto *idexpr = dynamic_cast<const IdExpression *>(argExpression);
  if (idexpr) {
    return calculateIdExpression(idexpr, parentExpr);
  }
  const auto *sse = dynamic_cast<const SubscriptExpression *>(argExpression);
  if (sse) {
    return calculateSubscriptExpression(sse, parentExpr);
  }
  const auto *fe = dynamic_cast<const FunctionExpression *>(argExpression);
  if (fe) {
    return calculateFunctionExpression(fe, parentExpr);
  }
  const auto *ce = dynamic_cast<const ConditionalExpression *>(argExpression);
  if (ce) {
    auto first = this->calculateExpression(parentExpr, ce->ifTrue.get());
    auto second = this->calculateExpression(parentExpr, ce->ifFalse.get());
    first.insert(first.end(), second.begin(), second.end());
    return first;
  }
  return {};
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::analyseBuildDefinition(const BuildDefinition *bd,
                                           const Node *parentExpr,
                                           const IdExpression *toResolve) {
  auto foundOurselves = false;
  std::vector<std::shared_ptr<InterpretNode>> tmp;
  for (const auto &stmt : bd->stmts | std::ranges::views::reverse) {
    if (stmt->equals(parentExpr)) {
      foundOurselves = true;
      continue;
    }
    if (!foundOurselves) {
      continue;
    }
    const auto *assignment =
        dynamic_cast<const AssignmentStatement *>(stmt.get());
    if (!assignment) {
      auto fullEval = this->fullEval(stmt.get(), toResolve);
      tmp.insert(tmp.end(), fullEval.begin(), fullEval.end());
      continue;
    }
    const auto *lhs = dynamic_cast<const IdExpression *>(assignment->lhs.get());
    if (!lhs || lhs->id != toResolve->id) {
      auto fullEval = this->fullEval(stmt.get(), toResolve);
      tmp.insert(tmp.end(), fullEval.begin(), fullEval.end());
      continue;
    }
    auto others = this->abstractEval(stmt.get(), assignment->rhs.get());
    if (assignment->op == AssignmentOperator::EQUALS) {
      others.insert(others.end(), tmp.begin(), tmp.end());
      return others;
    }
    tmp.insert(tmp.end(), others.begin(), others.end());
  }
  return tmp;
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::analyseIterationStatement(const IterationStatement *its,
                                              const Node *parentExpr,
                                              const IdExpression *toResolve) {
  auto foundOurselves = false;
  std::vector<std::shared_ptr<InterpretNode>> tmp;
  for (const auto &stmt : its->stmts | std::ranges::views::reverse) {
    if (stmt->equals(parentExpr)) {
      foundOurselves = true;
      continue;
    }
    if (!foundOurselves) {
      continue;
    }
    const auto *assignment =
        dynamic_cast<const AssignmentStatement *>(stmt.get());
    if (!assignment) {
      auto fullEval = this->fullEval(stmt.get(), toResolve);
      tmp.insert(tmp.end(), fullEval.begin(), fullEval.end());
      continue;
    }
    const auto *lhs = dynamic_cast<const IdExpression *>(assignment->lhs.get());
    if (!lhs || lhs->id != toResolve->id) {
      auto fullEval = this->fullEval(stmt.get(), toResolve);
      tmp.insert(tmp.end(), fullEval.begin(), fullEval.end());
      continue;
    }
    auto others = this->abstractEval(stmt.get(), assignment->rhs.get());
    if (assignment->op == AssignmentOperator::EQUALS) {
      others.insert(others.end(), tmp.begin(), tmp.end());
      return others;
    }
    tmp.insert(tmp.end(), others.begin(), others.end());
  }
  auto idx = 0;
  for (const auto &itsId : its->ids) {
    const auto *idexpr = dynamic_cast<const IdExpression *>(itsId.get());
    if (!idexpr || idexpr->id != toResolve->id) {
      idx++;
      continue;
    }
    auto vals = this->abstractEval(parentExpr->parent, its->expression.get());
    vals.insert(vals.end(), tmp.begin(), tmp.end());
    if (its->ids.size() == 1) {
      std::vector<std::shared_ptr<InterpretNode>> normalized;
      for (const auto &node : vals) {
        const auto *al = dynamic_cast<const ArrayLiteral *>(node->node);
        if (!al) {
          normalized.emplace_back(node);
          continue;
        }
        for (const auto &args : al->args) {
          auto tmp2 = this->abstractEval(its, args.get());
          normalized.insert(normalized.end(), tmp2.begin(), tmp2.end());
        }
      }
      return normalized;
    }
    std::vector<std::shared_ptr<InterpretNode>> ret;
    for (const auto &val : vals) {
      const auto *dictNode = dynamic_cast<const DictionaryLiteral *>(val->node);
      if (!dictNode) {
        continue;
      }
      for (const auto &kvi : dictNode->values) {
        const auto *kviN = dynamic_cast<const KeyValueItem *>(kvi.get());
        if (idx == 0) {
          auto evaled = this->abstractEval(kviN->key->parent, kviN->key.get());
          ret.insert(ret.end(), evaled.begin(), evaled.end());
        } else {
          auto evaled =
              this->abstractEval(kviN->value.get(), kviN->value.get());
          ret.insert(ret.end(), evaled.begin(), evaled.end());
        }
      }
    }
    return ret;
  }
  auto resolved = this->resolveArrayOrDict(its, toResolve);
  resolved.insert(resolved.end(), tmp.begin(), tmp.end());
  return resolved;
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::analyseSelectionStatement(const SelectionStatement *sst,
                                              const Node *parentExpr,
                                              const IdExpression *toResolve) {
  auto foundOurselves = false;
  std::vector<std::shared_ptr<InterpretNode>> tmp;
  for (const auto &block : sst->blocks | std::ranges::views::reverse) {
    for (const auto &stmt : block | std::ranges::views::reverse) {
      if (stmt->equals(parentExpr)) {
        foundOurselves = true;
        continue;
      }
      if (!foundOurselves) {
        continue;
      }
      const auto *assignment =
          dynamic_cast<const AssignmentStatement *>(stmt.get());
      if (!assignment) {
        auto fullEval = this->fullEval(stmt.get(), toResolve);
        tmp.insert(tmp.end(), fullEval.begin(), fullEval.end());
        continue;
      }
      const auto *lhs =
          dynamic_cast<const IdExpression *>(assignment->lhs.get());
      if (!lhs || lhs->id != toResolve->id) {
        auto fullEval = this->fullEval(stmt.get(), toResolve);
        tmp.insert(tmp.end(), fullEval.begin(), fullEval.end());
        continue;
      }
      auto others = this->abstractEval(stmt.get(), assignment->rhs.get());
      if (assignment->op == AssignmentOperator::EQUALS) {
        others.insert(others.end(), tmp.begin(), tmp.end());
        return others;
      }
      tmp.insert(tmp.end(), others.begin(), others.end());
    }
  }
  auto resolved = this->resolveArrayOrDict(sst, toResolve);
  resolved.insert(resolved.end(), tmp.begin(), tmp.end());
  return resolved;
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::resolveArrayOrDict(const Node *parentExpr,
                                       const IdExpression *toResolve) {
  const auto *parent = parentExpr->parent;
  const auto *bd = dynamic_cast<const BuildDefinition *>(parent);
  if (bd) {
    return analyseBuildDefinition(bd, parentExpr, toResolve);
  }
  const auto *its = dynamic_cast<const IterationStatement *>(parent);
  if (its) {
    return analyseIterationStatement(its, parentExpr, toResolve);
  }
  const auto *sst = dynamic_cast<const SelectionStatement *>(parent);
  if (sst) {
    return analyseSelectionStatement(sst, parentExpr, toResolve);
  }

  return {};
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::evalStatement(const Node *stmt,
                                  const IdExpression *toResolve) {
  const auto *ass = dynamic_cast<const AssignmentStatement *>(stmt);
  if (!ass) {
    return this->fullEval(stmt, toResolve);
  }
  const auto *lhs = dynamic_cast<const IdExpression *>(ass->lhs.get());
  if (!lhs || lhs->id != toResolve->id) {
    return this->fullEval(stmt, toResolve);
  }
  return this->abstractEval(ass, ass->rhs.get());
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::fullEval(const Node *stmt, const IdExpression *toResolve) {
  std::vector<std::shared_ptr<InterpretNode>> ret;
  const auto *bd = dynamic_cast<const BuildDefinition *>(stmt);
  if (bd) {
    for (const auto &blockStmt : bd->stmts | std::ranges::views::reverse) {
      auto evaled = this->evalStatement(blockStmt.get(), toResolve);
      ret.insert(ret.end(), evaled.begin(), evaled.end());
    }
  }
  const auto *its = dynamic_cast<const IterationStatement *>(stmt);
  if (its) {
    for (const auto &blockStmt : its->stmts | std::ranges::views::reverse) {
      auto evaled = this->evalStatement(blockStmt.get(), toResolve);
      ret.insert(ret.end(), evaled.begin(), evaled.end());
    }
    for (const auto &itsId : its->ids) {
      const auto *idExpr = dynamic_cast<const IdExpression *>(itsId.get());
      if (!idExpr || idExpr->id != toResolve->id) {
        continue;
      }
      auto evaled = this->evalStatement(itsId.get(), toResolve);
      ret.insert(ret.end(), evaled.begin(), evaled.end());
    }
  }
  const auto *sst = dynamic_cast<const SelectionStatement *>(stmt);
  if (sst) {
    for (const auto &block : sst->blocks | std::ranges::views::reverse) {
      for (const auto &blockStmt : block | std::ranges::views::reverse) {
        auto evaled = this->evalStatement(blockStmt.get(), toResolve);
        ret.insert(ret.end(), evaled.begin(), evaled.end());
      }
    }
  }
  return ret;
}

void PartialInterpreter::addToArrayConcatenated(
    const ArrayLiteral *arr, const std::string &contents,
    const std::string &sep, bool literalFirst,
    std::vector<std::shared_ptr<InterpretNode>> &ret) {
  for (const auto &arrArg : arr->args) {
    const auto *asStr = dynamic_cast<const StringLiteral *>(arrArg.get());
    if (!asStr) {
      continue;
    }
    const auto &full = literalFirst
                           ? std::format("{}{}{}", contents, sep, asStr->id)
                           : std::format("{}{}{}", asStr->id, sep, contents);
    ret.emplace_back(std::make_shared<ArtificialStringNode>(full));
  }
}

void PartialInterpreter::abstractEvalComputeBinaryExpr(
    const InterpretNode *left, const InterpretNode *right,
    const std::string &sep, std::vector<std::shared_ptr<InterpretNode>> &ret) {
  const auto *lnode = left->node;
  const auto *sll = dynamic_cast<const StringLiteral *>(lnode);
  const auto *rnode = right->node;
  const auto *slr = dynamic_cast<const StringLiteral *>(rnode);
  if (sll && slr) {
    std::string const str = sll->id + sep + slr->id;
    ret.emplace_back(std::make_shared<ArtificialStringNode>(str));
    return;
  }
  const auto *arrR = dynamic_cast<const ArrayLiteral *>(rnode);
  if (sll && arrR) {
    for (const auto &arrArg : arrR->args) {
      const auto *argSL = dynamic_cast<const StringLiteral *>(arrArg.get());
      if (argSL) {
        ret.emplace_back(
            std::make_shared<ArtificialStringNode>(sll->id + sep + argSL->id));
      }
      const auto *argAL = dynamic_cast<const ArrayLiteral *>(arrArg.get());
      if (argAL) {
        addToArrayConcatenated(argAL, sll->id, sep, true, ret);
      }
    }
    return;
  }
  const auto *arrL = dynamic_cast<const ArrayLiteral *>(lnode);
  if (slr && arrL) {
    for (const auto &arrArg : arrL->args) {
      const auto *argSL = dynamic_cast<const StringLiteral *>(arrArg.get());
      if (argSL) {
        ret.emplace_back(
            std::make_shared<ArtificialStringNode>(argSL->id + sep + slr->id));
      }
      const auto *argAL = dynamic_cast<const ArrayLiteral *>(arrArg.get());
      if (argAL) {
        addToArrayConcatenated(argAL, slr->id, sep, false, ret);
      }
    }
    return;
  }
  if (arrL && arrR) {
    ret.push_back(std::make_shared<ArrayNode>(arrL));
    ret.push_back(std::make_shared<ArrayNode>(arrR));
  }
  const auto *ldict = dynamic_cast<const DictionaryLiteral *>(lnode);
  const auto *rdict = dynamic_cast<const DictionaryLiteral *>(rnode);
  if (ldict && rdict) {
    ret.push_back(std::make_shared<DictNode>(ldict));
    ret.push_back(std::make_shared<DictNode>(rdict));
  }
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::abstractEvalBinaryExpression(const BinaryExpression *be,
                                                 const Node *parentStmt) {
  auto rhs = this->abstractEval(parentStmt, be->rhs.get());
  auto lhs = this->abstractEval(parentStmt, be->lhs.get());
  std::vector<std::shared_ptr<InterpretNode>> ret;
  const auto *sep = be->op == BinaryOperator::DIV ? "/" : "";
  for (const auto &left : lhs) {
    for (const auto &right : rhs) {
      abstractEvalComputeBinaryExpr(left.get(), right.get(), sep, ret);
    }
  }
  return ret;
}

void PartialInterpreter::abstractEvalComputeSubscriptExtractDictArray(
    const ArrayLiteral *arr, const StringLiteral *sl,
    std::vector<std::shared_ptr<InterpretNode>> &ret) {
  for (const auto &arrayItem : arr->args) {
    const auto *dict = dynamic_cast<const DictionaryLiteral *>(arrayItem.get());
    if (!dict) {
      continue;
    }
    for (const auto &keyValueNode : dict->values) {
      const auto *kvi = dynamic_cast<const KeyValueItem *>(keyValueNode.get());
      if (!kvi) {
        continue;
      }
      const auto &name = kvi->getKeyName();
      if (name != sl->id) {
        continue;
      }
      const auto *kviValue =
          dynamic_cast<const StringLiteral *>(kvi->value.get());
      if (kviValue && kviValue->id == sl->id) {
        ret.emplace_back(std::make_shared<StringNode>(kviValue));
      }
    }
  }
}

void PartialInterpreter::abstractEvalComputeSubscript(
    const InterpretNode *inner, const InterpretNode *outer,
    std::vector<std::shared_ptr<InterpretNode>> &ret) {
  const auto *arr = dynamic_cast<const ArrayLiteral *>(outer->node);
  const auto *idx = dynamic_cast<const IntegerLiteral *>(inner->node);
  if (arr && idx && idx->valueAsInt < arr->args.size()) {
    auto nodeAtIdx = arr->args[idx->valueAsInt];
    const auto *atIdxSL = dynamic_cast<const StringLiteral *>(nodeAtIdx.get());
    if (atIdxSL) {
      ret.emplace_back(std::make_shared<StringNode>(atIdxSL));
    }
    const auto *atIdxAL = dynamic_cast<const ArrayLiteral *>(nodeAtIdx.get());
    if (!atIdxAL) {
      return;
    }
    for (auto arrayItem : atIdxAL->args) {
      const auto *asStr = dynamic_cast<const StringLiteral *>(atIdxAL);
      if (asStr) {
        ret.emplace_back(std::make_shared<StringNode>(asStr));
      }
    }
    return;
  }
  const auto *dict = dynamic_cast<const DictionaryLiteral *>(outer->node);
  const auto *sl = dynamic_cast<const StringLiteral *>(inner->node);
  if (!sl) {
    return;
  }
  if (dict) {
    for (const auto &keyValueNode : dict->values) {
      const auto *kvi = dynamic_cast<const KeyValueItem *>(keyValueNode.get());
      if (!kvi) {
        continue;
      }
      const auto &name = kvi->getKeyName();
      if (name != sl->id) {
        continue;
      }
      const auto *kviValue =
          dynamic_cast<const StringLiteral *>(kvi->value.get());
      if (kviValue && kviValue->id == sl->id) {
        ret.emplace_back(std::make_shared<StringNode>(kviValue));
      }
    }
    return;
  }
  assert(arr);
  abstractEvalComputeSubscriptExtractDictArray(arr, sl, ret);
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::abstractEvalSubscriptExpression(
    const SubscriptExpression *sse, const Node *parentStmt) {
  auto outer = this->abstractEval(parentStmt, sse->outer.get());
  auto inner = this->abstractEval(parentStmt, sse->inner.get());
  std::vector<std::shared_ptr<InterpretNode>> ret;
  for (const auto &outerNode : outer) {
    for (const auto &innerNode : inner) {
      this->abstractEvalComputeSubscript(innerNode.get(), outerNode.get(), ret);
    }
    const auto *dictN =
        dynamic_cast<const DictionaryLiteral *>(outerNode->node);
    if (!dictN || !inner.empty()) {
      continue;
    }
    for (const auto &keyValueItem : dictN->values) {
      const auto *kvi = dynamic_cast<const KeyValueItem *>(keyValueItem.get());
      if (!kvi) {
        continue;
      }
      const auto *kviValue =
          dynamic_cast<const StringLiteral *>(kvi->value.get());
      if (kviValue) {
        ret.emplace_back(std::make_shared<StringNode>(kviValue));
      }
    }
  }
  return ret;
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::abstractEvalSplitWithSubscriptExpression(
    const IntegerLiteral *idx, const StringLiteral *sl,
    const MethodExpression *outerMe, const Node *parentStmt) {
  auto objs = this->abstractEval(parentStmt, outerMe->obj.get());
  std::vector<std::shared_ptr<InterpretNode>> ret;
  const auto &splitAt = sl->id;
  auto idxI = idx->valueAsInt;
  for (const auto &obj : objs) {
    const auto *sl1 = dynamic_cast<const StringLiteral *>(obj->node);
    if (sl1) {
      auto parts = split(sl1->id, splitAt);
      if (idxI < parts.size()) {
        ret.emplace_back(std::make_shared<ArtificialStringNode>(parts[idxI]));
      }
      continue;
    }
    const auto *arr = dynamic_cast<const ArrayLiteral *>(obj->node);
    if (!arr) {
      continue;
    }
    for (const auto &arrArg : arr->args) {
      const auto *sl2 = dynamic_cast<const StringLiteral *>(arrArg.get());
      if (!sl2) {
        continue;
      }
      auto parts = split(sl2->id, splitAt);
      if (idxI < parts.size()) {
        ret.emplace_back(std::make_shared<ArtificialStringNode>(parts[idxI]));
      }
    }
  }
  return ret;
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::abstractEvalSplitByWhitespace(
    const IntegerLiteral *idx, const MethodExpression *outerMe,
    const Node *parentStmt) {
  auto objs = this->abstractEval(parentStmt, outerMe->obj.get());
  std::vector<std::shared_ptr<InterpretNode>> ret;
  auto idxI = idx->valueAsInt;
  for (const auto &obj : objs) {
    const auto *sl1 = dynamic_cast<const StringLiteral *>(obj->node);
    if (sl1) {
      auto parts = splitString(sl1->id);
      if (idxI < parts.size()) {
        ret.emplace_back(std::make_shared<ArtificialStringNode>(parts[idxI]));
      }
      continue;
    }
    const auto *arr = dynamic_cast<const ArrayLiteral *>(obj->node);
    if (!arr) {
      continue;
    }
    for (const auto &arrArg : arr->args) {
      const auto *sl2 = dynamic_cast<const StringLiteral *>(arrArg.get());
      if (!sl2) {
        continue;
      }
      auto parts = splitString(sl2->id);
      if (idxI < parts.size()) {
        ret.emplace_back(std::make_shared<ArtificialStringNode>(parts[idxI]));
      }
    }
  }
  return ret;
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::abstractEvalMethod(const MethodExpression *me,
                                       const Node *parentStmt) {
  auto meobj = this->abstractEval(parentStmt, me->obj.get());
  const auto *meid = dynamic_cast<const IdExpression *>(me->id.get());
  std::vector<std::shared_ptr<InterpretNode>> ret;
  if (!meid) {
    return ret;
  }
  for (const auto &deducedObjects : meobj) {
    std::vector<std::string> strValues;
    const auto *arr = dynamic_cast<const ArrayLiteral *>(deducedObjects->node);
    if (arr) {
      for (const auto &arrayItem : arr->args) {
        const auto *sl = dynamic_cast<const StringLiteral *>(arrayItem.get());
        if (sl) {
          strValues.push_back(sl->id);
        }
      }
    }
    const auto *sl = dynamic_cast<const StringLiteral *>(deducedObjects->node);
    if (sl) {
      strValues.emplace_back(sl->id);
    }
    if (meid->id != "keys") {
      for (const auto &str : strValues) {
        ret.emplace_back(std::make_shared<ArtificialStringNode>(
            applyMethod(str, meid->id, me->args)));
      }
    }
    const auto *dictionaryLiteral =
        dynamic_cast<const DictionaryLiteral *>(deducedObjects->node);
    if (!dictionaryLiteral || meid->id != "keys") {
      continue;
    }
    for (const auto &kvin : dictionaryLiteral->values) {
      const auto *kvi = dynamic_cast<const KeyValueItem *>(kvin.get());
      if (!kvi) {
        continue;
      }
      const auto &name = kvi->getKeyName();
      if (name != INVALID_KEY_NAME) {
        ret.emplace_back(std::make_shared<StringNode>(kvi->key.get()));
      }
    }
  }
  return ret;
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::abstractEvalSimpleSubscriptExpression(
    const SubscriptExpression *sse, const IdExpression *outerObj,
    const Node *parentStmt) {
  auto objs = this->resolveArrayOrDict(parentStmt, outerObj);
  std::vector<std::shared_ptr<InterpretNode>> ret;
  for (const auto &deducedObjs : objs) {
    const auto *arr = dynamic_cast<const ArrayLiteral *>(deducedObjs->node);
    const auto *idx = dynamic_cast<const IntegerLiteral *>(sse->inner.get());
    if (arr && idx && idx->valueAsInt < arr->args.size()) {
      auto nodeAtIdx = arr->args[idx->valueAsInt];
      const auto *atIdxSL =
          dynamic_cast<const StringLiteral *>(nodeAtIdx.get());
      if (atIdxSL) {
        ret.push_back(std::make_shared<StringNode>(atIdxSL));
        continue;
      }
      const auto *atIdxAL = dynamic_cast<const ArrayLiteral *>(nodeAtIdx.get());
      if (!atIdxAL) {
        continue;
      }
      for (const auto &arrayItem : atIdxAL->args) {
        const auto *asSL = dynamic_cast<const StringLiteral *>(arrayItem.get());
        if (asSL) {
          ret.push_back(std::make_shared<StringNode>(asSL));
        }
      }
      continue;
    }
    if (dynamic_cast<const StringNode *>(deducedObjs.get()) ||
        dynamic_cast<const ArtificialStringNode *>(deducedObjs.get())) {
      ret.emplace_back(deducedObjs);
      continue;
    }
    const auto *sl = dynamic_cast<const StringLiteral *>(sse->inner.get());
    const auto *dict =
        dynamic_cast<const DictionaryLiteral *>(deducedObjs->node);
    if (sl && dict) {
      for (const auto &keyValueNode : dict->values) {
        const auto *kvi =
            dynamic_cast<const KeyValueItem *>(keyValueNode.get());
        if (!kvi) {
          continue;
        }
        const auto &name = kvi->getKeyName();
        if (name != sl->id) {
          continue;
        }
        const auto *kviValue =
            dynamic_cast<const StringLiteral *>(kvi->value.get());
        if (kviValue) {
          ret.emplace_back(std::make_shared<StringNode>(kviValue));
        }
      }
      continue;
    }
    if (arr && sl) {
      abstractEvalComputeSubscriptExtractDictArray(arr, sl, ret);
    }
  }
  return ret;
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::abstractEvalGetMethodCall(const MethodExpression * /*me*/,
                                              const IdExpression *meobj,
                                              const ArgumentList *al,
                                              const Node *parentStmt) {
  std::vector<std::shared_ptr<InterpretNode>> ret;
  auto objs = this->resolveArrayOrDict(parentStmt, meobj);
  for (const auto &deducedObj : objs) {
    const auto *arr = dynamic_cast<const ArrayLiteral *>(deducedObj->node);
    const auto *idx = dynamic_cast<const IntegerLiteral *>(al->args[0].get());
    if (arr && idx && idx->valueAsInt < arr->args.size()) {
      const auto *atIdx =
          dynamic_cast<const StringLiteral *>(arr->args[idx->valueAsInt].get());
      if (atIdx) {
        ret.emplace_back(std::make_shared<StringNode>(atIdx));
      }
      continue;
    }
    if (dynamic_cast<const StringNode *>(deducedObj.get())) {
      ret.emplace_back(std::make_shared<StringNode>(deducedObj->node));
      continue;
    }
    const auto *sl = dynamic_cast<const StringLiteral *>(al->args[0].get());
    const auto *dict =
        dynamic_cast<const DictionaryLiteral *>(deducedObj->node);
    if (sl && dict) {
      for (const auto &keyValueItem : dict->values) {
        const auto *kvi =
            dynamic_cast<const KeyValueItem *>(keyValueItem.get());
        if (!kvi) {
          continue;
        }
        const auto &name = kvi->getKeyName();
        if (name != sl->id) {
          continue;
        }
        const auto *kviValue =
            dynamic_cast<const StringLiteral *>(kvi->value.get());
        if (kviValue) {
          ret.emplace_back(std::make_shared<StringNode>(kviValue));
        }
      }
    }
  }
  return ret;
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::abstractEvalArrayLiteral(const ArrayLiteral *al,
                                             const Node *toEval,
                                             const Node *parentStmt) {
  if (al->args.empty()) {
    return {std::make_shared<ArrayNode>(toEval)};
  }
  const auto *firstArg = al->args[0].get();
  std::vector<std::shared_ptr<InterpretNode>> ret;

  for (const auto &arrayItem : al->args) {
    if (dynamic_cast<const ArrayLiteral *>(firstArg)) {
      ret.emplace_back(std::make_shared<ArrayNode>(arrayItem.get()));
    } else if (dynamic_cast<const DictionaryLiteral *>(firstArg)) {
      ret.emplace_back(std::make_shared<DictNode>(arrayItem.get()));
    } else if (dynamic_cast<const IdExpression *>(firstArg)) {
      auto resolved = this->resolveArrayOrDict(
          parentStmt, dynamic_cast<const IdExpression *>(firstArg));
      ret.insert(ret.end(), resolved.begin(), resolved.end());
    }
  }
  return ret;
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::abstractEvalGenericSubscriptExpression(
    const SubscriptExpression *sse, const Node *parentStmt) {
  const auto *inner = sse->inner.get();
  const auto *outer = sse->outer.get();
  if ((dynamic_cast<const StringLiteral *>(inner) ||
       dynamic_cast<const IntegerLiteral *>(inner)) &&
      dynamic_cast<const IdExpression *>(outer)) {
    return abstractEvalSimpleSubscriptExpression(
        sse, dynamic_cast<const IdExpression *>(outer), parentStmt);
  }
  const auto *idx = dynamic_cast<const IntegerLiteral *>(inner);
  const auto *outerME = dynamic_cast<const MethodExpression *>(outer);
  if (idx && outerME) {
    const auto *meId = dynamic_cast<const IdExpression *>(outerME->id.get());
    if (!meId || meId->id != "split") {
      return this->abstractEvalSubscriptExpression(sse, parentStmt);
    }
    const auto *al = dynamic_cast<const ArgumentList *>(outerME->args.get());
    if (!al) {
      return this->abstractEvalSubscriptExpression(sse, parentStmt);
    }
    if (al->args.empty()) {
      return this->abstractEvalSplitByWhitespace(idx, outerME, parentStmt);
    }
    const auto *sl = dynamic_cast<const StringLiteral *>(al->args[0].get());
    if (sl) {
      return this->abstractEvalSplitWithSubscriptExpression(idx, sl, outerME,
                                                            parentStmt);
    }
  }
  return this->abstractEvalSubscriptExpression(sse, parentStmt);
}

std::vector<std::shared_ptr<InterpretNode>> allAbstractStringCombinations(
    std::vector<std::vector<std::shared_ptr<InterpretNode>>> arrays) {
  if (arrays.empty()) {
    return {};
  }
  if (arrays.size() == 1) {
    return arrays[0];
  }
  auto restCombinations = allAbstractStringCombinations(
      std::vector<std::vector<std::shared_ptr<InterpretNode>>>{
          arrays.begin() + 1, arrays.end()});
  auto firstArray = arrays[0];
  std::vector<decltype(arrays)::value_type>(arrays.begin() + 1, arrays.end())
      .swap(arrays);
  std::vector<std::shared_ptr<InterpretNode>> combinations;
  for (const auto &string : firstArray) {
    const auto *outerStr = dynamic_cast<const StringLiteral *>(string->node);
    if (!outerStr) {
      continue;
    }
    for (const auto &combination : restCombinations) {
      const auto *sl = dynamic_cast<const StringLiteral *>(combination->node);
      if (!sl) {
        continue;
      }
      combinations.emplace_back(
          std::make_shared<ArtificialStringNode>(outerStr->id + "/" + sl->id));
    }
  }
  return combinations;
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::abstractEvalFunction(const FunctionExpression *fe,
                                         const Node *parentStmt) {
  const auto *al = dynamic_cast<const ArgumentList *>(fe->args.get());
  if (!al) {
    return {};
  }
  const auto *feid = dynamic_cast<const IdExpression *>(fe->id.get());
  if (!feid) {
    return {};
  }
  const auto &fnid = feid->id;
  if (fnid == "join_paths") {
    std::vector<std::vector<std::shared_ptr<InterpretNode>>> items;
    for (const auto &arrayItem : al->args) {
      if (dynamic_cast<const KeywordItem *>(arrayItem.get())) {
        continue;
      }
      items.emplace_back(this->abstractEval(parentStmt, arrayItem.get()));
    }
    return allAbstractStringCombinations(items);
  }
  if (fnid != "get_option") {
    return {};
  }
  const auto *first = dynamic_cast<const StringLiteral *>(al->args[0].get());
  if (!first) {
    return {};
  }
  auto option = this->options.findOption(first->id);
  if (!option) {
    return {};
  }
  std::vector<std::shared_ptr<InterpretNode>> ret;
  const auto *comboOpt = dynamic_cast<const ComboOption *>(option.get());
  if (comboOpt) {
    for (const auto &val : comboOpt->values) {
      ret.emplace_back(std::make_shared<ArtificialStringNode>(val));
    }
  }
  const auto *arrayOpt = dynamic_cast<const ArrayOption *>(option.get());
  if (arrayOpt) {
    for (const auto &val : arrayOpt->choices) {
      ret.emplace_back(std::make_shared<ArtificialStringNode>(val));
    }
  }
  return ret;
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::abstractEval(const Node *parentStmt, const Node *toEval) {
  const auto *dict = dynamic_cast<const DictionaryLiteral *>(toEval);
  if (dict) {
    return {std::make_shared<DictNode>(dict)};
  }
  const auto *arrL = dynamic_cast<const ArrayLiteral *>(toEval);
  if (arrL) {
    return {std::make_shared<ArrayNode>(arrL)};
  }
  const auto *slL = dynamic_cast<const StringLiteral *>(toEval);
  if (slL) {
    return {std::make_shared<StringNode>(slL)};
  }
  const auto *ilL = dynamic_cast<const IntegerLiteral *>(toEval);
  if (ilL) {
    return {std::make_shared<IntNode>(ilL)};
  }
  const auto *be = dynamic_cast<const BinaryExpression *>(toEval);
  if (be) {
    return abstractEvalBinaryExpression(be, parentStmt);
  }
  const auto *idexpr = dynamic_cast<const IdExpression *>(toEval);
  if (idexpr) {
    return resolveArrayOrDict(parentStmt, idexpr);
  }
  const auto *me = dynamic_cast<const MethodExpression *>(toEval);
  if (me && me->args) {
    const auto *meid = dynamic_cast<const IdExpression *>(me->id.get());
    if (meid->id == "format" && me->args) {
      const auto &strs = calculateStringFormatMethodCall(
          me, dynamic_cast<const ArgumentList *>(me->args.get()), parentStmt);
      std::vector<std::shared_ptr<InterpretNode>> ret;
      ret.reserve(strs.size());
      for (const auto &str : strs) {
        ret.emplace_back(std::make_shared<ArtificialStringNode>(str));
      }
      return ret;
    }
    if (!meid || meid->id != "get") {
      goto next;
    }
    const auto *meObj = dynamic_cast<const IdExpression *>(me->obj.get());
    const auto *al = dynamic_cast<const ArgumentList *>(me->args.get());
    if (!al || al->args.empty() || !meObj) {
      goto next;
    }
    return this->abstractEvalGetMethodCall(me, meObj, al, parentStmt);
  }
next:
  if (me && !me->args) {
    const auto *meid = dynamic_cast<const IdExpression *>(me->id.get());
    if (meid->id != "split") {
      goto next2;
    }
    std::vector<std::shared_ptr<InterpretNode>> nodes;
    auto evaled = this->abstractEval(parentStmt, me->obj.get());
    for (const auto &eval : evaled) {
      const auto *slNode = dynamic_cast<const StringLiteral *>(eval->node);
      if (!slNode) {
        continue;
      }
      auto parts = splitString(slNode->id);
      for (const auto &part : parts) {
        nodes.push_back(std::make_shared<ArtificialStringNode>(part));
      }
    }
    auto ret = std::make_shared<ArtificialArrayNode>(nodes);
    this->keepAlives.push_back(ret);
    return {ret};
  }
next2:
  if (me && isValidMethod(me)) {
    return this->abstractEvalMethod(me, parentStmt);
  }
  const auto *ce = dynamic_cast<const ConditionalExpression *>(toEval);
  if (ce) {
    auto ret = this->abstractEval(parentStmt, ce->ifTrue.get());
    const auto &ifFalse = this->abstractEval(parentStmt, ce->ifFalse.get());
    ret.insert(ret.end(), ifFalse.begin(), ifFalse.end());
    return ret;
  }
  const auto *sse = dynamic_cast<const SubscriptExpression *>(toEval);
  if (sse) {
    return this->abstractEvalGenericSubscriptExpression(sse, parentStmt);
  }
  const auto *fe = dynamic_cast<const FunctionExpression *>(toEval);
  if (fe && isValidFunction(fe)) {
    return this->abstractEvalFunction(fe, parentStmt);
  }
  const auto *ass = dynamic_cast<const AssignmentStatement *>(toEval);
  if (ass) {
    return this->abstractEval(parentStmt, ass->rhs.get());
  }
  return {};
}

bool isValidFunction(const FunctionExpression *fe) {
  std::set<std::string> const funcs{"join_paths", "get_option"};
  return funcs.contains(fe->functionName());
}

bool isValidMethod(const MethodExpression *me) {
  const auto *meid = dynamic_cast<const IdExpression *>(me->id.get());
  if (!meid) {
    return false;
  }
  std::set<std::string> const names{"underscorify", "to_lower", "to_upper",
                                    "strip",        "keys",     "replace"};
  return names.contains(meid->id);
}

std::string applyMethod(const std::string &deduced, const std::string &name,
                        const std::shared_ptr<Node> &args) {
  if (name == "underscorify") {
    std::string ret;
    ret.reserve(deduced.size());
    for (auto chr : deduced) {
      if (std::isalnum(chr) != 0) {
        ret.push_back(chr);
      } else {
        ret.push_back('_');
      }
    }
    return ret;
  }
  if (name == "to_lower") {
    std::string data;
    std::ranges::transform(deduced, std::back_inserter(data),
                           [](unsigned char chr) { return std::tolower(chr); });
    return data;
  }
  if (name == "replace") {
    if (!args) {
      return deduced;
    }
    if (args->type != NodeType::ARGUMENT_LIST) {
      return deduced;
    }
    const auto &argList = static_cast<ArgumentList *>(args.get())->args;
    if (argList.size() != 2) {
      return deduced;
    }
    const auto &arg1 = argList[0];
    const auto &arg2 = argList[1];
    if (arg1->type != NodeType::STRING_LITERAL ||
        arg2->type != NodeType::STRING_LITERAL) {
      return deduced;
    }
    std::string data = deduced;
    const auto &from = static_cast<StringLiteral *>(arg1.get())->id;
    const auto &to = static_cast<StringLiteral *>(arg2.get())->id;
    replace(data, from, to);
    return data;
  }
  if (name == "to_upper") {
    std::string data;
    std::ranges::transform(deduced, std::back_inserter(data),
                           [](unsigned char chr) { return std::toupper(chr); });
    return data;
  }
  if (name == "strip") {
    auto data = deduced;
    trim(data);
    return data;
  }
  std::unreachable();
}

std::vector<std::string> splitString(const std::string &str) {
  std::vector<std::string> result;
  std::istringstream iss(str);
  std::string word;

  while (iss >> word) {
    result.push_back(word);
  }

  return result;
}
