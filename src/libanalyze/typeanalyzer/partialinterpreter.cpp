// HERE BE DRAGONS
#include "partialinterpreter.hpp"

#include "log.hpp"
#include "mesonoption.hpp"
#include "node.hpp"
#include "optionstate.hpp"
#include "utils.hpp"

#include <algorithm>
#include <cassert>
#include <cctype>
#include <cstdint>
#include <memory>
#include <ranges>
#include <set>
#include <sstream>
#include <string>
#include <vector>

static Logger LOG("typeanalyzer::partialinterpreter"); // NOLINT

std::vector<std::shared_ptr<InterpretNode>> allAbstractStringCombinations(
    std::vector<std::vector<std::shared_ptr<InterpretNode>>> arrays);
bool isValidMethod(MethodExpression *me);
std::string applyMethod(const std::string &deduced, const std::string &name);
bool isValidFunction(FunctionExpression *fe);
std::vector<std::string> splitString(const std::string &str);

std::vector<std::string> guessSetVariable(FunctionExpression *fe,
                                          OptionState &opts) {
  auto *al = dynamic_cast<ArgumentList *>(fe->args.get());
  if (!al || al->args.empty()) {
    return {};
  }
  auto toCalculate = al->args[0];
  Node *parent = fe;
  while (true) {
    auto *probableParent = parent->parent;
    if (dynamic_cast<IterationStatement *>(probableParent) ||
        dynamic_cast<SelectionStatement *>(probableParent) ||
        dynamic_cast<BuildDefinition *>(probableParent)) {
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
  auto *al = dynamic_cast<ArgumentList *>(fe->args.get());
  if (!al || al->args.empty()) {
    return {};
  }
  auto toCalculate = al->getKwarg(kwargName);
  if (!toCalculate) {
    return {};
  }
  Node *parent = fe;
  while (true) {
    auto *probableParent = parent->parent;
    if (dynamic_cast<IterationStatement *>(probableParent) ||
        dynamic_cast<SelectionStatement *>(probableParent) ||
        dynamic_cast<BuildDefinition *>(probableParent)) {
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
  auto *al = dynamic_cast<ArgumentList *>(me->args.get());
  if (!al || al->args.empty()) {
    return {};
  }
  auto toCalculate = al->args[0];
  Node *parent = me;
  while (true) {
    auto *probableParent = parent->parent;
    if (dynamic_cast<IterationStatement *>(probableParent) ||
        dynamic_cast<SelectionStatement *>(probableParent) ||
        dynamic_cast<BuildDefinition *>(probableParent)) {
      break;
    }
    parent = parent->parent;
  }
  PartialInterpreter calc(opts);
  return calc.calculate(parent, toCalculate.get());
}

std::vector<std::string> PartialInterpreter::calculate(Node *parent,
                                                       Node *exprToCalculate) {
  return this->calculateExpression(parent, exprToCalculate);
}

std::vector<std::string>
PartialInterpreter::calculateBinaryExpression(Node *parentExpr,
                                              BinaryExpression *be) {
  auto lhs = this->calculateExpression(parentExpr, be->lhs.get());
  auto rhs = this->calculateExpression(parentExpr, be->rhs.get());
  std::vector<std::string> ret;
  const auto *opStr = be->op == BinaryOperator::Div ? "/" : "";
  for (const auto &left : lhs) {
    for (const auto &right : rhs) {
      ret.emplace_back(std::format("{}{}{}", left, opStr, right));
    }
  }
  return ret;
}

std::vector<std::string> PartialInterpreter::calculateStringFormatMethodCall(
    MethodExpression *me, ArgumentList *al, Node *parentExpr) {
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
    ArgumentList *al, IdExpression *meObj, Node *parentExpr) {
  auto nodes = this->resolveArrayOrDict(parentExpr, meObj);
  std::vector<std::string> ret;
  auto first = al->args[0];
  auto *il = dynamic_cast<IntegerLiteral *>(first.get());
  auto idx = il ? il->valueAsInt : (uint64_t)-1;
  auto *sl = dynamic_cast<StringLiteral *>(first.get());
  for (const auto &node : nodes) {
    auto *arrLit = dynamic_cast<ArrayLiteral *>(node->node);
    if (arrLit) {
      if (il) {
        if (idx < arrLit->args.size()) {
          auto *slAtIdx =
              dynamic_cast<StringLiteral *>(arrLit->args[idx].get());
          ret.emplace_back(slAtIdx->id);
        }
        continue;
      }
      if (!sl) {
        continue;
      }
      for (const auto &arrayItem : arrLit->args) {
        auto *dict = dynamic_cast<DictionaryLiteral *>(arrayItem.get());
        if (!dict) {
          continue;
        }
        for (const auto &keyValueNode : dict->values) {
          auto *kvi = dynamic_cast<KeyValueItem *>(keyValueNode.get());
          if (!kvi) {
            continue;
          }
          auto name = kvi->getKeyName();
          if (name != sl->id) {
            continue;
          }
          auto *kviValue = dynamic_cast<StringLiteral *>(kvi->value.get());
          if (kviValue) {
            ret.emplace_back(kviValue->id);
          }
        }
      }
      continue;
    }
    auto *dict = dynamic_cast<DictionaryLiteral *>(node->node);
    if (!dict || !sl) {
      continue;
    }
    for (const auto &kviNode : dict->values) {
      auto *kvi = dynamic_cast<KeyValueItem *>(kviNode.get());
      if (!kvi) {
        continue;
      }
      auto name = kvi->getKeyName();
      if (name != sl->id) {
        continue;
      }
      auto *kviValue = dynamic_cast<StringLiteral *>(kvi->value.get());
      if (kviValue) {
        ret.emplace_back(kviValue->id);
      }
    }
  }
  return ret;
}

std::vector<std::string>
PartialInterpreter::calculateIdExpression(IdExpression *idExpr,
                                          Node *parentExpr) {
  auto found = this->resolveArrayOrDict(parentExpr, idExpr);
  std::vector<std::string> ret;
  for (const auto &foundNode : found) {
    auto *node = foundNode->node;
    auto *stringNode = dynamic_cast<StringLiteral *>(node);
    if (stringNode) {
      ret.emplace_back(stringNode->id);
      continue;
    }
    auto *arrayNode = dynamic_cast<ArrayNode *>(foundNode.get());
    if (!arrayNode) {
      continue;
    }
    auto *al = dynamic_cast<ArrayLiteral *>(node);
    if (!al) {
      continue;
    }
    for (const auto &arg : al->args) {
      auto *sl = dynamic_cast<StringLiteral *>(arg.get());
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
  auto *first = inner->node;
  auto *il = dynamic_cast<IntegerLiteral *>(first);
  auto idx = il ? il->valueAsInt : (uint64_t)-1;
  auto *sl = dynamic_cast<StringLiteral *>(first);
  auto *arrLit = dynamic_cast<ArrayLiteral *>(outer->node);
  if (arrLit) {
    if (il) {
      if (idx < arrLit->args.size()) {
        auto *slAtIdx = dynamic_cast<StringLiteral *>(arrLit->args[idx].get());
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
      auto *dict = dynamic_cast<DictionaryLiteral *>(arrayItem.get());
      if (!dict) {
        continue;
      }
      for (const auto &keyValueNode : dict->values) {
        auto *kvi = dynamic_cast<KeyValueItem *>(keyValueNode.get());
        if (!kvi) {
          continue;
        }
        auto name = kvi->getKeyName();
        if (name != sl->id) {
          continue;
        }
        auto *kviValue = dynamic_cast<StringLiteral *>(kvi->value.get());
        if (kviValue) {
          ret.emplace_back(kviValue->id);
        }
      }
    }
    return;
  }
  auto *dict = dynamic_cast<DictionaryLiteral *>(outer->node);
  if (!dict || !sl) {
    return;
  }
  for (const auto &keyValueNode : dict->values) {
    auto *kvi = dynamic_cast<KeyValueItem *>(keyValueNode.get());
    if (!kvi) {
      continue;
    }
    auto name = kvi->getKeyName();
    if (name != sl->id) {
      continue;
    }
    auto *kviValue = dynamic_cast<StringLiteral *>(kvi->value.get());
    if (kviValue) {
      ret.emplace_back(kviValue->id);
    }
  }
}

std::vector<std::string>
PartialInterpreter::calculateSubscriptExpression(SubscriptExpression *sse,
                                                 Node *parentExpr) {
  auto outerNodes = this->abstractEval(parentExpr, sse->outer.get());
  auto innerNodes = this->abstractEval(parentExpr, sse->inner.get());
  std::vector<std::string> ret;
  for (const auto &outer : outerNodes) {
    for (const auto &inner : innerNodes) {
      this->calculateEvalSubscriptExpression(inner, outer, ret);
    }
    auto *dictN = dynamic_cast<DictionaryLiteral *>(outer->node);
    if (!dictN || !innerNodes.empty()) {
      continue;
    }
    for (const auto &keyValueNode : dictN->values) {
      auto *kvi = dynamic_cast<KeyValueItem *>(keyValueNode.get());
      if (!kvi) {
        continue;
      }
      auto *sl = dynamic_cast<StringLiteral *>(kvi->value.get());
      if (sl) {
        ret.emplace_back(sl->id);
      }
    }
  }
  return ret;
}

std::vector<std::string>
PartialInterpreter::calculateFunctionExpression(FunctionExpression *fe,
                                                Node *parentExpr) {
  std::set<std::string> const funcs{"join_paths", "get_option"};
  std::vector<std::string> ret;
  auto func = fe->function;
  auto *feId = dynamic_cast<IdExpression *>(fe->id.get());
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
  auto *args = dynamic_cast<ArgumentList *>(al.get());
  if (!args) {
    return ret;
  }
  if (feId->id == "get_option") {
    if (args->args.empty()) {
      return ret;
    }
    auto *first = dynamic_cast<StringLiteral *>(args->args[0].get());
    if (!first) {
      return ret;
    }
    auto option = this->options.findOption(first->id);
    if (!option) {
      return ret;
    }
    auto *comboOpt = dynamic_cast<ComboOption *>(option.get());
    if (comboOpt) {
      return comboOpt->values;
    }
    auto *arrayOpt = dynamic_cast<ArrayOption *>(option.get());
    if (arrayOpt) {
      return arrayOpt->choices;
    }
    return ret;
  }
  std::vector<std::vector<std::shared_ptr<InterpretNode>>> items;
  for (const auto &arrayItem : args->args) {
    if (dynamic_cast<KeywordItem *>(arrayItem.get())) {
      continue;
    }
    auto evaled = this->abstractEval(parentExpr, arrayItem.get());
    items.emplace_back(evaled);
  }
  auto combinations = allAbstractStringCombinations(items);
  for (const auto &combo : combinations) {
    auto *sl = dynamic_cast<StringLiteral *>(combo->node);
    if (sl) {
      ret.emplace_back(sl->id);
    }
  }
  return ret;
}

std::vector<std::string>
PartialInterpreter::calculateExpression(Node *parentExpr, Node *argExpression) {
  auto *sl = dynamic_cast<StringLiteral *>(argExpression);
  if (sl) {
    return std::vector<std::string>{sl->id};
  }
  auto *be = dynamic_cast<BinaryExpression *>(argExpression);
  if (be) {
    return this->calculateBinaryExpression(parentExpr, be);
  }
  auto *me = dynamic_cast<MethodExpression *>(argExpression);
  if (me) {
    auto *meId = dynamic_cast<IdExpression *>(me->id.get());
    if (!meId) {
      return {};
    }
    if (isValidMethod(me)) {
      auto objStrs = this->calculateExpression(parentExpr, me->obj.get());
      std::vector<std::string> ret;
      ret.reserve(objStrs.size());
      for (const auto &objStr : objStrs) {
        ret.emplace_back(applyMethod(objStr, meId->id));
      }
      return ret;
    }
    if (!me->args) {
      return {};
    }
    auto *al = dynamic_cast<ArgumentList *>(me->args.get());
    if (!al || al->args.empty()) {
      return {};
    }
    if (meId->id == "format") {
      return this->calculateStringFormatMethodCall(me, al, parentExpr);
    }
    auto *meObj = dynamic_cast<IdExpression *>(me->obj.get());
    if (meId->id == "get" && meObj) {
      return this->calculateGetMethodCall(al, meObj, parentExpr);
    }
  }
  auto *idexpr = dynamic_cast<IdExpression *>(argExpression);
  if (idexpr) {
    return calculateIdExpression(idexpr, parentExpr);
  }
  auto *sse = dynamic_cast<SubscriptExpression *>(argExpression);
  if (sse) {
    return calculateSubscriptExpression(sse, parentExpr);
  }
  auto *fe = dynamic_cast<FunctionExpression *>(argExpression);
  if (fe) {
    return calculateFunctionExpression(fe, parentExpr);
  }
  auto *ce = dynamic_cast<ConditionalExpression *>(argExpression);
  if (ce) {
    auto first = this->calculateExpression(parentExpr, ce->ifTrue.get());
    auto second = this->calculateExpression(parentExpr, ce->ifFalse.get());
    first.insert(first.end(), second.begin(), second.end());
    return first;
  }
  return {};
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::analyseBuildDefinition(BuildDefinition *bd,
                                           Node *parentExpr,
                                           IdExpression *toResolve) {
  auto foundOurselves = false;
  std::vector<std::shared_ptr<InterpretNode>> tmp;
  for (auto &stmt : bd->stmts | std::ranges::views::reverse) {
    if (stmt->equals(parentExpr)) {
      foundOurselves = true;
      continue;
    }
    if (!foundOurselves) {
      continue;
    }
    auto *assignment = dynamic_cast<AssignmentStatement *>(stmt.get());
    if (!assignment) {
      auto fullEval = this->fullEval(stmt.get(), toResolve);
      tmp.insert(tmp.end(), fullEval.begin(), fullEval.end());
      continue;
    }
    auto *lhs = dynamic_cast<IdExpression *>(assignment->lhs.get());
    if (!lhs || lhs->id != toResolve->id) {
      auto fullEval = this->fullEval(stmt.get(), toResolve);
      tmp.insert(tmp.end(), fullEval.begin(), fullEval.end());
      continue;
    }
    auto others = this->abstractEval(stmt.get(), assignment->rhs.get());
    if (assignment->op == AssignmentOperator::Equals) {
      others.insert(others.end(), tmp.begin(), tmp.end());
      return others;
    }
    tmp.insert(tmp.end(), others.begin(), others.end());
  }
  return tmp;
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::analyseIterationStatement(IterationStatement *its,
                                              Node *parentExpr,
                                              IdExpression *toResolve) {
  auto foundOurselves = false;
  std::vector<std::shared_ptr<InterpretNode>> tmp;
  for (auto &stmt : its->stmts | std::ranges::views::reverse) {
    if (stmt->equals(parentExpr)) {
      foundOurselves = true;
      continue;
    }
    if (!foundOurselves) {
      continue;
    }
    auto *assignment = dynamic_cast<AssignmentStatement *>(stmt.get());
    if (!assignment) {
      auto fullEval = this->fullEval(stmt.get(), toResolve);
      tmp.insert(tmp.end(), fullEval.begin(), fullEval.end());
      continue;
    }
    auto *lhs = dynamic_cast<IdExpression *>(assignment->lhs.get());
    if (!lhs || lhs->id != toResolve->id) {
      auto fullEval = this->fullEval(stmt.get(), toResolve);
      tmp.insert(tmp.end(), fullEval.begin(), fullEval.end());
      continue;
    }
    auto others = this->abstractEval(stmt.get(), assignment->rhs.get());
    if (assignment->op == AssignmentOperator::Equals) {
      others.insert(others.end(), tmp.begin(), tmp.end());
      return others;
    }
    tmp.insert(tmp.end(), others.begin(), others.end());
  }
  auto idx = 0;
  for (const auto &itsId : its->ids) {
    auto *idexpr = dynamic_cast<IdExpression *>(itsId.get());
    if (!idexpr || idexpr->id != toResolve->id) {
      idx++;
      continue;
    }
    auto vals = this->abstractEval(parentExpr->parent, its->expression.get());
    vals.insert(vals.end(), tmp.begin(), tmp.end());
    if (its->ids.size() == 1) {
      std::vector<std::shared_ptr<InterpretNode>> normalized;
      for (const auto &node : vals) {
        auto *al = dynamic_cast<ArrayLiteral *>(node->node);
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
      auto *dictNode = dynamic_cast<DictionaryLiteral *>(val->node);
      if (!dictNode) {
        continue;
      }
      for (const auto &kvi : dictNode->values) {
        auto *kviN = dynamic_cast<KeyValueItem *>(kvi.get());
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
PartialInterpreter::analyseSelectionStatement(SelectionStatement *sst,
                                              Node *parentExpr,
                                              IdExpression *toResolve) {
  auto foundOurselves = false;
  std::vector<std::shared_ptr<InterpretNode>> tmp;
  for (auto &block : sst->blocks | std::ranges::views::reverse) {
    for (const auto &stmt : block | std::ranges::views::reverse) {
      if (stmt->equals(parentExpr)) {
        foundOurselves = true;
        continue;
      }
      if (!foundOurselves) {
        continue;
      }
      auto *assignment = dynamic_cast<AssignmentStatement *>(stmt.get());
      if (!assignment) {
        auto fullEval = this->fullEval(stmt.get(), toResolve);
        tmp.insert(tmp.end(), fullEval.begin(), fullEval.end());
        continue;
      }
      auto *lhs = dynamic_cast<IdExpression *>(assignment->lhs.get());
      if (!lhs || lhs->id != toResolve->id) {
        auto fullEval = this->fullEval(stmt.get(), toResolve);
        tmp.insert(tmp.end(), fullEval.begin(), fullEval.end());
        continue;
      }
      auto others = this->abstractEval(stmt.get(), assignment->rhs.get());
      if (assignment->op == AssignmentOperator::Equals) {
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
PartialInterpreter::resolveArrayOrDict(Node *parentExpr,
                                       IdExpression *toResolve) {
  auto *parent = parentExpr->parent;
  auto *bd = dynamic_cast<BuildDefinition *>(parent);
  if (bd) {
    return analyseBuildDefinition(bd, parentExpr, toResolve);
  }
  auto *its = dynamic_cast<IterationStatement *>(parent);
  if (its) {
    return analyseIterationStatement(its, parentExpr, toResolve);
  }
  auto *sst = dynamic_cast<SelectionStatement *>(parent);
  if (sst) {
    return analyseSelectionStatement(sst, parentExpr, toResolve);
  }

  return {};
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::evalStatement(Node *stmt, IdExpression *toResolve) {
  auto *ass = dynamic_cast<AssignmentStatement *>(stmt);
  if (!ass) {
    return this->fullEval(stmt, toResolve);
  }
  auto *lhs = dynamic_cast<IdExpression *>(ass->lhs.get());
  if (!lhs || lhs->id != toResolve->id) {
    return this->fullEval(stmt, toResolve);
  }
  return this->abstractEval(ass, ass->rhs.get());
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::fullEval(Node *stmt, IdExpression *toResolve) {
  std::vector<std::shared_ptr<InterpretNode>> ret;
  auto *bd = dynamic_cast<BuildDefinition *>(stmt);
  if (bd) {
    for (auto &stmt : bd->stmts | std::ranges::views::reverse) {
      auto evaled = this->evalStatement(stmt.get(), toResolve);
      ret.insert(ret.end(), evaled.begin(), evaled.end());
    }
  }
  auto *its = dynamic_cast<IterationStatement *>(stmt);
  if (its) {
    for (auto &stmt : its->stmts | std::ranges::views::reverse) {
      auto evaled = this->evalStatement(stmt.get(), toResolve);
      ret.insert(ret.end(), evaled.begin(), evaled.end());
    }
    for (const auto &itsId : its->ids) {
      auto *idExpr = dynamic_cast<IdExpression *>(itsId.get());
      if (!idExpr || idExpr->id != toResolve->id) {
        continue;
      }
      auto evaled = this->evalStatement(itsId.get(), toResolve);
      ret.insert(ret.end(), evaled.begin(), evaled.end());
    }
  }
  auto *sst = dynamic_cast<SelectionStatement *>(stmt);
  if (sst) {
    for (auto &block : sst->blocks | std::ranges::views::reverse) {
      for (const auto &stmt : block | std::ranges::views::reverse) {
        auto evaled = this->evalStatement(stmt.get(), toResolve);
        ret.insert(ret.end(), evaled.begin(), evaled.end());
      }
    }
  }
  return ret;
}

void PartialInterpreter::addToArrayConcatenated(
    ArrayLiteral *arr, const std::string &contents, const std::string &sep,
    bool literalFirst, std::vector<std::shared_ptr<InterpretNode>> &ret) {
  for (const auto &arrArg : arr->args) {
    auto *asStr = dynamic_cast<StringLiteral *>(arrArg.get());
    if (!asStr) {
      continue;
    }
    auto full = literalFirst ? (contents + sep + asStr->id)
                             : (asStr->id + sep + contents);
    ret.emplace_back(std::make_shared<ArtificialStringNode>(full));
  }
}

void PartialInterpreter::abstractEvalComputeBinaryExpr(
    InterpretNode *left, InterpretNode *right, const std::string &sep,
    std::vector<std::shared_ptr<InterpretNode>> &ret) {
  auto *lnode = left->node;
  auto *sll = dynamic_cast<StringLiteral *>(lnode);
  auto *rnode = right->node;
  auto *slr = dynamic_cast<StringLiteral *>(rnode);
  if (sll && slr) {
    std::string const str = sll->id + sep + slr->id;
    ret.emplace_back(std::make_shared<ArtificialStringNode>(str));
    return;
  }
  auto *arrR = dynamic_cast<ArrayLiteral *>(rnode);
  if (sll && arrR) {
    for (const auto &arrArg : arrR->args) {
      auto *argSL = dynamic_cast<StringLiteral *>(arrArg.get());
      if (argSL) {
        ret.emplace_back(
            std::make_shared<ArtificialStringNode>(sll->id + sep + argSL->id));
      }
      auto *argAL = dynamic_cast<ArrayLiteral *>(arrArg.get());
      if (argAL) {
        addToArrayConcatenated(argAL, sll->id, sep, true, ret);
      }
    }
    return;
  }
  auto *arrL = dynamic_cast<ArrayLiteral *>(lnode);
  if (slr && arrL) {
    for (const auto &arrArg : arrL->args) {
      auto *argSL = dynamic_cast<StringLiteral *>(arrArg.get());
      if (argSL) {
        ret.emplace_back(
            std::make_shared<ArtificialStringNode>(argSL->id + sep + slr->id));
      }
      auto *argAL = dynamic_cast<ArrayLiteral *>(arrArg.get());
      if (argAL) {
        addToArrayConcatenated(argAL, slr->id, sep, false, ret);
      }
    }
    return;
  }
  auto *ldict = dynamic_cast<DictionaryLiteral *>(lnode);
  auto *rdict = dynamic_cast<DictionaryLiteral *>(rnode);
  if (ldict && rdict) {
    ret.push_back(std::make_shared<DictNode>(ldict));
    ret.push_back(std::make_shared<DictNode>(rdict));
  }
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::abstractEvalBinaryExpression(BinaryExpression *be,
                                                 Node *parentStmt) {
  auto rhs = this->abstractEval(parentStmt, be->rhs.get());
  auto lhs = this->abstractEval(parentStmt, be->lhs.get());
  std::vector<std::shared_ptr<InterpretNode>> ret;
  const auto *sep = be->op == BinaryOperator::Div ? "/" : "";
  for (const auto &left : lhs) {
    for (const auto &right : rhs) {
      abstractEvalComputeBinaryExpr(left.get(), right.get(), sep, ret);
    }
  }
  return ret;
}

void PartialInterpreter::abstractEvalComputeSubscriptExtractDictArray(
    ArrayLiteral *arr, StringLiteral *sl,
    std::vector<std::shared_ptr<InterpretNode>> &ret) {
  for (const auto &arrayItem : arr->args) {
    auto *dict = dynamic_cast<DictionaryLiteral *>(arrayItem.get());
    if (!dict) {
      continue;
    }
    for (const auto &keyValueNode : dict->values) {
      auto *kvi = dynamic_cast<KeyValueItem *>(keyValueNode.get());
      if (!kvi) {
        continue;
      }
      auto name = kvi->getKeyName();
      if (name != sl->id) {
        continue;
      }
      auto *kviValue = dynamic_cast<StringLiteral *>(kvi->value.get());
      if (kviValue && kviValue->id == sl->id) {
        ret.emplace_back(std::make_shared<StringNode>(kviValue));
      }
    }
  }
}

void PartialInterpreter::abstractEvalComputeSubscript(
    InterpretNode *inner, InterpretNode *outer,
    std::vector<std::shared_ptr<InterpretNode>> &ret) {
  auto *arr = dynamic_cast<ArrayLiteral *>(outer->node);
  auto *idx = dynamic_cast<IntegerLiteral *>(inner->node);
  if (arr && idx && idx->valueAsInt < arr->args.size()) {
    auto nodeAtIdx = arr->args[idx->valueAsInt];
    auto *atIdxSL = dynamic_cast<StringLiteral *>(nodeAtIdx.get());
    if (atIdxSL) {
      ret.emplace_back(std::make_shared<StringNode>(atIdxSL));
    }
    auto *atIdxAL = dynamic_cast<ArrayLiteral *>(nodeAtIdx.get());
    if (atIdxAL) {
      for (auto arrayItem : atIdxAL->args) {
        auto *asStr = dynamic_cast<StringLiteral *>(atIdxAL);
        if (asStr) {
          ret.emplace_back(std::make_shared<StringNode>(asStr));
        }
      }
    }
    return;
  }
  auto *dict = dynamic_cast<DictionaryLiteral *>(outer->node);
  auto *sl = dynamic_cast<StringLiteral *>(inner->node);
  if (dict && sl) {
    for (const auto &keyValueNode : dict->values) {
      auto *kvi = dynamic_cast<KeyValueItem *>(keyValueNode.get());
      if (!kvi) {
        continue;
      }
      auto name = kvi->getKeyName();
      if (name != sl->id) {
        continue;
      }
      auto *kviValue = dynamic_cast<StringLiteral *>(kvi->value.get());
      if (kviValue && kviValue->id == sl->id) {
        ret.emplace_back(std::make_shared<StringNode>(kviValue));
      }
    }
    return;
  }
  if (arr && sl) {
    abstractEvalComputeSubscriptExtractDictArray(arr, sl, ret);
  }
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::abstractEvalSubscriptExpression(SubscriptExpression *sse,
                                                    Node *parentStmt) {
  auto outer = this->abstractEval(parentStmt, sse->outer.get());
  auto inner = this->abstractEval(parentStmt, sse->inner.get());
  std::vector<std::shared_ptr<InterpretNode>> ret;
  for (const auto &outerNode : outer) {
    for (const auto &innerNode : inner) {
      this->abstractEvalComputeSubscript(innerNode.get(), outerNode.get(), ret);
    }
    auto *dictN = dynamic_cast<DictionaryLiteral *>(outerNode->node);
    if (!dictN || !inner.empty()) {
      continue;
    }
    for (const auto &keyValueItem : dictN->values) {
      auto *kvi = dynamic_cast<KeyValueItem *>(keyValueItem.get());
      if (!kvi) {
        continue;
      }
      auto *kviValue = dynamic_cast<StringLiteral *>(kvi->value.get());
      if (kviValue) {
        ret.emplace_back(std::make_shared<StringNode>(kviValue));
      }
    }
  }
  return ret;
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::abstractEvalSplitWithSubscriptExpression(
    IntegerLiteral *idx, StringLiteral *sl, MethodExpression *outerMe,
    Node *parentStmt) {
  auto objs = this->abstractEval(parentStmt, outerMe->obj.get());
  std::vector<std::shared_ptr<InterpretNode>> ret;
  auto splitAt = sl->id;
  auto idxI = idx->valueAsInt;
  for (const auto &obj : objs) {
    auto *sl1 = dynamic_cast<StringLiteral *>(obj->node);
    if (sl1) {
      auto parts = split(sl1->id, splitAt);
      if (idxI < parts.size()) {
        ret.emplace_back(std::make_shared<ArtificialStringNode>(parts[idxI]));
      }
      continue;
    }
    auto *arr = dynamic_cast<ArrayLiteral *>(obj->node);
    if (!arr) {
      continue;
    }
    for (const auto &arrArg : arr->args) {
      auto *sl1 = dynamic_cast<StringLiteral *>(arrArg.get());
      if (!sl1) {
        continue;
      }
      auto parts = split(sl1->id, splitAt);
      if (idxI < parts.size()) {
        ret.emplace_back(std::make_shared<ArtificialStringNode>(parts[idxI]));
      }
    }
  }
  return ret;
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::abstractEvalSplitByWhitespace(IntegerLiteral *idx,
                                                  MethodExpression *outerMe,
                                                  Node *parentStmt) {
  auto objs = this->abstractEval(parentStmt, outerMe->obj.get());
  std::vector<std::shared_ptr<InterpretNode>> ret;
  auto idxI = idx->valueAsInt;
  for (const auto &obj : objs) {
    auto *sl1 = dynamic_cast<StringLiteral *>(obj->node);
    if (sl1) {
      auto parts = splitString(sl1->id);
      if (idxI < parts.size()) {
        ret.emplace_back(std::make_shared<ArtificialStringNode>(parts[idxI]));
      }
      continue;
    }
    auto *arr = dynamic_cast<ArrayLiteral *>(obj->node);
    if (!arr) {
      continue;
    }
    for (const auto &arrArg : arr->args) {
      auto *sl1 = dynamic_cast<StringLiteral *>(arrArg.get());
      if (!sl1) {
        continue;
      }
      auto parts = splitString(sl1->id);
      if (idxI < parts.size()) {
        ret.emplace_back(std::make_shared<ArtificialStringNode>(parts[idxI]));
      }
    }
  }
  return ret;
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::abstractEvalMethod(MethodExpression *me, Node *parentStmt) {
  auto meobj = this->abstractEval(parentStmt, me->obj.get());
  auto *meid = dynamic_cast<IdExpression *>(me->id.get());
  std::vector<std::shared_ptr<InterpretNode>> ret;
  if (!meid) {
    return ret;
  }
  for (const auto &deducedObjects : meobj) {
    std::vector<std::string> strValues;
    auto *arr = dynamic_cast<ArrayLiteral *>(deducedObjects->node);
    if (arr) {
      for (const auto &arrayItem : arr->args) {
        auto *sl = dynamic_cast<StringLiteral *>(arrayItem.get());
        if (sl) {
          strValues.push_back(sl->id);
        }
      }
    }
    auto *sl = dynamic_cast<StringLiteral *>(deducedObjects->node);
    if (sl) {
      strValues.emplace_back(sl->id);
    }
    if (meid->id != "keys") {
      for (const auto &str : strValues) {
        ret.emplace_back(
            std::make_shared<ArtificialStringNode>(applyMethod(str, meid->id)));
      }
    }
    auto *dictionaryLiteral =
        dynamic_cast<DictionaryLiteral *>(deducedObjects->node);
    if (!dictionaryLiteral || meid->id != "keys") {
      continue;
    }
    for (const auto &kvin : dictionaryLiteral->values) {
      auto *kvi = dynamic_cast<KeyValueItem *>(kvin.get());
      if (!kvi) {
        continue;
      }
      auto name = kvi->getKeyName();
      if (name != INVALID_KEY_NAME) {
        ret.emplace_back(std::make_shared<StringNode>(kvi->key.get()));
      }
    }
  }
  return ret;
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::abstractEvalSimpleSubscriptExpression(
    SubscriptExpression *sse, IdExpression *outerObj, Node *parentStmt) {
  auto objs = this->resolveArrayOrDict(parentStmt, outerObj);
  std::vector<std::shared_ptr<InterpretNode>> ret;
  for (const auto &deducedObjs : objs) {
    auto *arr = dynamic_cast<ArrayLiteral *>(deducedObjs->node);
    auto *idx = dynamic_cast<IntegerLiteral *>(sse->inner.get());
    if (arr && idx && idx->valueAsInt < arr->args.size()) {
      auto nodeAtIdx = arr->args[idx->valueAsInt];
      auto *atIdxSL = dynamic_cast<StringLiteral *>(nodeAtIdx.get());
      if (atIdxSL) {
        ret.push_back(std::make_shared<StringNode>(atIdxSL));
        continue;
      }
      auto *atIdxAL = dynamic_cast<ArrayLiteral *>(nodeAtIdx.get());
      if (!atIdxAL) {
        continue;
      }
      for (const auto &arrayItem : atIdxAL->args) {
        auto *asSL = dynamic_cast<StringLiteral *>(arrayItem.get());
        if (asSL) {
          ret.push_back(std::make_shared<StringNode>(asSL));
        }
      }
      continue;
    }
    if (dynamic_cast<StringNode *>(deducedObjs.get()) ||
        dynamic_cast<ArtificialStringNode *>(deducedObjs.get())) {
      ret.emplace_back(deducedObjs);
      continue;
    }
    auto *sl = dynamic_cast<StringLiteral *>(sse->inner.get());
    auto *dict = dynamic_cast<DictionaryLiteral *>(deducedObjs->node);
    if (sl && dict) {
      for (const auto &keyValueNode : dict->values) {
        auto *kvi = dynamic_cast<KeyValueItem *>(keyValueNode.get());
        if (!kvi) {
          continue;
        }
        auto name = kvi->getKeyName();
        if (name != sl->id) {
          continue;
        }
        auto *kviValue = dynamic_cast<StringLiteral *>(kvi->value.get());
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
PartialInterpreter::abstractEvalGetMethodCall(MethodExpression * /*me*/,
                                              IdExpression *meobj,
                                              ArgumentList *al,
                                              Node *parentStmt) {
  std::vector<std::shared_ptr<InterpretNode>> ret;
  auto objs = this->resolveArrayOrDict(parentStmt, meobj);
  for (const auto &deducedObj : objs) {
    auto *arr = dynamic_cast<ArrayLiteral *>(deducedObj->node);
    auto *idx = dynamic_cast<IntegerLiteral *>(al->args[0].get());
    if (arr && idx && idx->valueAsInt < arr->args.size()) {
      auto *atIdx =
          dynamic_cast<StringLiteral *>(arr->args[idx->valueAsInt].get());
      if (atIdx) {
        ret.emplace_back(std::make_shared<StringNode>(atIdx));
      }
      continue;
    }
    if (dynamic_cast<StringNode *>(deducedObj.get())) {
      ret.emplace_back(std::make_shared<StringNode>(deducedObj->node));
      continue;
    }
    auto *sl = dynamic_cast<StringLiteral *>(al->args[0].get());
    auto *dict = dynamic_cast<DictionaryLiteral *>(deducedObj->node);
    if (sl && dict) {
      for (const auto &keyValueItem : dict->values) {
        auto *kvi = dynamic_cast<KeyValueItem *>(keyValueItem.get());
        if (!kvi) {
          continue;
        }
        auto name = kvi->getKeyName();
        if (name != sl->id) {
          continue;
        }
        auto *kviValue = dynamic_cast<StringLiteral *>(kvi->value.get());
        if (kviValue) {
          ret.emplace_back(std::make_shared<StringNode>(kviValue));
        }
      }
    }
  }
  return ret;
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::abstractEvalArrayLiteral(ArrayLiteral *al, Node *toEval,
                                             Node *parentStmt) {
  if (al->args.empty()) {
    return {std::make_shared<ArrayNode>(toEval)};
  }
  auto *firstArg = al->args[0].get();
  std::vector<std::shared_ptr<InterpretNode>> ret;

  for (const auto &arrayItem : al->args) {
    if (dynamic_cast<ArrayLiteral *>(firstArg)) {
      ret.emplace_back(std::make_shared<ArrayNode>(arrayItem.get()));
    } else if (dynamic_cast<DictionaryLiteral *>(firstArg)) {
      ret.emplace_back(std::make_shared<DictNode>(arrayItem.get()));
    } else if (dynamic_cast<IdExpression *>(firstArg)) {
      auto resolved = this->resolveArrayOrDict(
          parentStmt, dynamic_cast<IdExpression *>(firstArg));
      ret.insert(ret.end(), resolved.begin(), resolved.end());
    }
  }
  return ret;
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::abstractEvalGenericSubscriptExpression(
    SubscriptExpression *sse, Node *parentStmt) {
  auto *inner = sse->inner.get();
  auto *outer = sse->outer.get();
  if ((dynamic_cast<StringLiteral *>(inner) ||
       dynamic_cast<IntegerLiteral *>(inner)) &&
      dynamic_cast<IdExpression *>(outer)) {
    return abstractEvalSimpleSubscriptExpression(
        sse, dynamic_cast<IdExpression *>(outer), parentStmt);
  }
  auto *idx = dynamic_cast<IntegerLiteral *>(inner);
  auto *outerME = dynamic_cast<MethodExpression *>(outer);
  if (idx && outerME) {
    auto *meId = dynamic_cast<IdExpression *>(outerME->id.get());
    if (!meId || meId->id != "split") {
      return this->abstractEvalSubscriptExpression(sse, parentStmt);
    }
    auto *al = dynamic_cast<ArgumentList *>(outerME->args.get());
    if (!al) {
      return this->abstractEvalSubscriptExpression(sse, parentStmt);
    }
    if (al->args.empty()) {
      return this->abstractEvalSplitByWhitespace(idx, outerME, parentStmt);
    }
    auto *sl = dynamic_cast<StringLiteral *>(al->args[0].get());
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
    auto *outerStr = dynamic_cast<StringLiteral *>(string->node);
    if (!outerStr) {
      continue;
    }
    for (const auto &combination : restCombinations) {
      auto *sl = dynamic_cast<StringLiteral *>(combination->node);
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
PartialInterpreter::abstractEvalFunction(FunctionExpression *fe,
                                         Node *parentStmt) {
  auto *al = dynamic_cast<ArgumentList *>(fe->args.get());
  if (!al) {
    return {};
  }
  auto *feid = dynamic_cast<IdExpression *>(fe->id.get());
  if (!feid) {
    return {};
  }
  auto fnid = feid->id;
  if (fnid == "join_paths") {
    std::vector<std::vector<std::shared_ptr<InterpretNode>>> items;
    for (const auto &arrayItem : al->args) {
      if (dynamic_cast<KeywordItem *>(arrayItem.get())) {
        continue;
      }
      items.emplace_back(this->abstractEval(parentStmt, arrayItem.get()));
    }
    return allAbstractStringCombinations(items);
  }
  if (fnid != "get_option") {
    return {};
  }
  auto *first = dynamic_cast<StringLiteral *>(al->args[0].get());
  if (!first) {
    return {};
  }
  auto option = this->options.findOption(first->id);
  if (!option) {
    return {};
  }
  std::vector<std::shared_ptr<InterpretNode>> ret;
  auto *comboOpt = dynamic_cast<ComboOption *>(option.get());
  if (comboOpt) {
    for (const auto &val : comboOpt->values) {
      ret.emplace_back(std::make_shared<ArtificialStringNode>(val));
    }
  }
  auto *arrayOpt = dynamic_cast<ArrayOption *>(option.get());
  if (arrayOpt) {
    for (const auto &val : arrayOpt->choices) {
      ret.emplace_back(std::make_shared<ArtificialStringNode>(val));
    }
  }
  return ret;
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::abstractEval(Node *parentStmt, Node *toEval) {
  auto *dict = dynamic_cast<DictionaryLiteral *>(toEval);
  if (dict) {
    return {std::make_shared<DictNode>(dict)};
  }
  auto *arrL = dynamic_cast<ArrayLiteral *>(toEval);
  if (arrL) {
    return {std::make_shared<ArrayNode>(arrL)};
  }
  auto *slL = dynamic_cast<StringLiteral *>(toEval);
  if (slL) {
    return {std::make_shared<StringNode>(slL)};
  }
  auto *ilL = dynamic_cast<IntegerLiteral *>(toEval);
  if (ilL) {
    return {std::make_shared<IntNode>(ilL)};
  }
  auto *be = dynamic_cast<BinaryExpression *>(toEval);
  if (be) {
    return abstractEvalBinaryExpression(be, parentStmt);
  }
  auto *idexpr = dynamic_cast<IdExpression *>(toEval);
  if (idexpr) {
    return resolveArrayOrDict(parentStmt, idexpr);
  }
  auto *me = dynamic_cast<MethodExpression *>(toEval);
  if (me && me->args) {
    auto *meid = dynamic_cast<IdExpression *>(me->id.get());
    if (meid->id == "format" && me->args) {
      auto strs = calculateStringFormatMethodCall(
          me, dynamic_cast<ArgumentList *>(me->args.get()), parentStmt);
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
    auto *meObj = dynamic_cast<IdExpression *>(me->obj.get());
    auto *al = dynamic_cast<ArgumentList *>(me->args.get());
    if (!al || al->args.empty()) {
      goto next;
    }
    return this->abstractEvalGetMethodCall(me, meObj, al, parentStmt);
  }
next:
  if (me && !me->args) {
    auto *meid = dynamic_cast<IdExpression *>(me->id.get());
    if (meid->id != "split") {
      goto next2;
    }
    std::vector<std::shared_ptr<InterpretNode>> nodes;
    auto evaled = this->abstractEval(parentStmt, me->obj.get());
    for (const auto &eval : evaled) {
      auto *slNode = dynamic_cast<StringLiteral *>(eval->node);
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
  auto *ce = dynamic_cast<ConditionalExpression *>(toEval);
  if (ce) {
    auto ret = this->abstractEval(parentStmt, ce->ifTrue.get());
    auto ifFalse = this->abstractEval(parentStmt, ce->ifFalse.get());
    ret.insert(ret.end(), ifFalse.begin(), ifFalse.end());
    return ret;
  }
  auto *sse = dynamic_cast<SubscriptExpression *>(toEval);
  if (sse) {
    return this->abstractEvalGenericSubscriptExpression(sse, parentStmt);
  }
  auto *fe = dynamic_cast<FunctionExpression *>(toEval);
  if (fe && isValidFunction(fe)) {
    return this->abstractEvalFunction(fe, parentStmt);
  }
  auto *ass = dynamic_cast<AssignmentStatement *>(toEval);
  if (ass) {
    return this->abstractEval(parentStmt, ass->rhs.get());
  }
  return {};
}

bool isValidFunction(FunctionExpression *fe) {
  std::set<std::string> const funcs{"join_paths", "get_option"};
  return funcs.contains(fe->functionName());
}

bool isValidMethod(MethodExpression *me) {
  auto *meid = dynamic_cast<IdExpression *>(me->id.get());
  if (!meid) {
    return false;
  }
  std::set<std::string> const names{"underscorify", "to_lower", "to_upper",
                                    "strip", "keys"};
  return names.contains(meid->id);
}

std::string applyMethod(const std::string &deduced, const std::string &name) {
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
    std::string data = deduced;
    std::transform(data.begin(), data.end(), data.begin(),
                   [](unsigned char chr) { return std::tolower(chr); });
    return data;
  }
  if (name == "to_upper") {
    std::string data = deduced;
    std::transform(data.begin(), data.end(), data.begin(),
                   [](unsigned char chr) { return std::toupper(chr); });
    return data;
  }
  if (name == "strip") {
    auto data = deduced;
    trim(data);
    return data;
  }
  assert(false);
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
