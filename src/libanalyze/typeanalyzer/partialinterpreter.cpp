// HERE BE DRAGONS
#include "partialinterpreter.hpp"

#include "log.hpp"
#include "mesonoption.hpp"
#include "node.hpp"
#include "utils.hpp"

#include <algorithm>
#include <cassert>
#include <cctype>
#include <cstdint>
#include <memory>
#include <ranges>
#include <string>
#include <vector>

static Logger LOG("typeanalyzer::partialinterpreter"); // NOLINT

std::vector<std::shared_ptr<InterpretNode>> allAbstractStringCombinations(
    std::vector<std::vector<std::shared_ptr<InterpretNode>>> arrays);
bool isValidMethod(MethodExpression *me);
std::string applyMethod(std::string varname, std::string name);
bool isValidFunction(FunctionExpression *fe);

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
  }
  PartialInterpreter calc(opts);
  return calc.calculate(parent, toCalculate.get());
}

std::vector<std::string> guessGetVariableMethod(MethodExpression *me,
                                                OptionState &opts) {
  auto al = dynamic_cast<ArgumentList *>(me->args.get());
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
  for (auto l : lhs) {
    for (auto r : rhs) {
      ret.emplace_back(l + opStr + r);
    }
  }
  return ret;
}

std::vector<std::string> PartialInterpreter::calculateStringFormatMethodCall(
    MethodExpression *me, ArgumentList *al, Node *parentExpr) {
  auto objStrs = this->calculateExpression(parentExpr, me->obj.get());
  auto fmtStrs = this->calculateExpression(parentExpr, al->args[0].get());
  std::vector<std::string> ret;
  for (auto o : objStrs) {
    for (auto f : fmtStrs) {
      auto copy = std::string(o);
      auto raw = replace(copy, "@0@", f);
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
  for (auto r : nodes) {
    auto *arrLit = dynamic_cast<ArrayLiteral *>(r->node);
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
      for (auto a : arrLit->args) {
        auto dict = dynamic_cast<DictionaryLiteral *>(a.get());
        if (!dict) {
          continue;
        }
        for (auto k : dict->values) {
          auto kvi = dynamic_cast<KeyValueItem *>(k.get());
          if (!kvi) {
            continue;
          }
          auto name = kvi->getKeyName();
          if (name != sl->id) {
            continue;
          }
          auto kviValue = dynamic_cast<StringLiteral *>(kvi->value.get());
          if (kviValue) {
            ret.emplace_back(kviValue->id);
          }
        }
      }
      continue;
    }
    auto dict = dynamic_cast<DictionaryLiteral *>(r->node);
    if (!dict || !sl) {
      continue;
    }
    for (auto k : dict->values) {
      auto kvi = dynamic_cast<KeyValueItem *>(k.get());
      if (!kvi) {
        continue;
      }
      auto name = kvi->getKeyName();
      if (name != sl->id) {
        continue;
      }
      auto kviValue = dynamic_cast<StringLiteral *>(kvi->value.get());
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
  auto l = this->resolveArrayOrDict(parentExpr, idExpr);
  std::vector<std::string> ret;
  for (auto v : l) {
    auto node = v->node;
    auto sn = dynamic_cast<StringLiteral *>(node);
    if (sn) {
      ret.emplace_back(sn->id);
      continue;
    }
    auto an = dynamic_cast<ArrayNode *>(v.get());
    if (!an) {
      continue;
    }
    auto al = dynamic_cast<ArrayLiteral *>(node);
    if (!al) {
      continue;
    }
    for (auto arg : al->args) {
      auto sl = dynamic_cast<StringLiteral *>(arg.get());
      if (sl) {
        ret.emplace_back(sl->id);
      }
    }
  }
  return ret;
}

void PartialInterpreter::calculateEvalSubscriptExpression(
    std::shared_ptr<InterpretNode> i, std::shared_ptr<InterpretNode> o,
    std::vector<std::string> &ret) {
  auto first = i->node;
  auto *il = dynamic_cast<IntegerLiteral *>(first);
  auto idx = il ? il->valueAsInt : (uint64_t)-1;
  auto *sl = dynamic_cast<StringLiteral *>(first);
  auto arrLit = dynamic_cast<ArrayLiteral *>(o->node);
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
    for (auto a : arrLit->args) {
      auto dict = dynamic_cast<DictionaryLiteral *>(a.get());
      if (!dict) {
        continue;
      }
      for (auto k : dict->values) {
        auto kvi = dynamic_cast<KeyValueItem *>(k.get());
        if (!kvi) {
          continue;
        }
        auto name = kvi->getKeyName();
        if (name != sl->id) {
          continue;
        }
        auto kviValue = dynamic_cast<StringLiteral *>(kvi->value.get());
        if (kviValue) {
          ret.emplace_back(kviValue->id);
        }
      }
    }
    return;
  }
  auto dict = dynamic_cast<DictionaryLiteral *>(o->node);
  if (!dict || !sl) {
    return;
  }
  for (auto k : dict->values) {
    auto kvi = dynamic_cast<KeyValueItem *>(k.get());
    if (!kvi) {
      continue;
    }
    auto name = kvi->getKeyName();
    if (name != sl->id) {
      continue;
    }
    auto kviValue = dynamic_cast<StringLiteral *>(kvi->value.get());
    if (kviValue) {
      ret.emplace_back(kviValue->id);
    }
  }
}

std::vector<std::string>
PartialInterpreter::calculateSubscriptExpression(SubscriptExpression *sse,
                                                 Node *parentExpr) {
  auto outer = this->abstractEval(parentExpr, sse->outer.get());
  auto inner = this->abstractEval(parentExpr, sse->inner.get());
  std::vector<std::string> ret;
  for (auto o : outer) {
    for (auto i : inner) {
      this->calculateEvalSubscriptExpression(i, o, ret);
    }
    auto dictN = dynamic_cast<DictionaryLiteral *>(o->node);
    if (!dictN || !inner.empty()) {
      continue;
    }
    for (auto n : dictN->values) {
      auto kvi = dynamic_cast<KeyValueItem *>(n.get());
      if (!kvi) {
        continue;
      }
      auto sl = dynamic_cast<StringLiteral *>(kvi->value.get());
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
  std::set<std::string> funcs{"join_paths", "get_option"};
  std::vector<std::string> ret;
  auto fn = fe->function;
  auto *feId = dynamic_cast<IdExpression *>(fe->id.get());
  if (!feId) {
    return ret;
  }
  if (!fn) {
    if (!funcs.contains(feId->id)) {
      return ret;
    }
  } else {
    if (!funcs.contains(fn->name)) {
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
    auto co = dynamic_cast<ComboOption *>(option.get());
    if (co) {
      return co->values;
    }
    auto ao = dynamic_cast<ArrayOption *>(option.get());
    if (ao) {
      return ao->choices;
    }
    return ret;
  }
  std::vector<std::vector<std::shared_ptr<InterpretNode>>> items;
  for (const auto &a : args->args) {
    if (dynamic_cast<KeywordItem *>(a.get())) {
      continue;
    }
    auto evaled = this->abstractEval(parentExpr, a.get());
    items.emplace_back(evaled);
  }
  auto combinations = allAbstractStringCombinations(items);
  for (const auto &combo : combinations) {
    auto sl = dynamic_cast<StringLiteral *>(combo->node);
    if (sl) {
      ret.emplace_back(sl->id);
    }
  }
  return ret;
}

std::vector<std::string>
PartialInterpreter::calculateExpression(Node *parentExpr, Node *argExpression) {
  auto sl = dynamic_cast<StringLiteral *>(argExpression);
  if (sl) {
    return std::vector<std::string>{sl->id};
  }
  auto be = dynamic_cast<BinaryExpression *>(argExpression);
  if (be) {
    return this->calculateBinaryExpression(parentExpr, be);
  }
  auto me = dynamic_cast<MethodExpression *>(argExpression);
  if (me) {
    auto meId = dynamic_cast<IdExpression *>(me->id.get());
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
    auto al = dynamic_cast<ArgumentList *>(me->args.get());
    if (!al || al->args.empty()) {
      return {};
    }
    if (meId->id == "format") {
      return this->calculateStringFormatMethodCall(me, al, parentExpr);
    }
    auto meObj = dynamic_cast<IdExpression *>(me->obj.get());
    if (meId->id == "get" && meObj) {
      return this->calculateGetMethodCall(al, meObj, parentExpr);
    }
  }
  auto idexpr = dynamic_cast<IdExpression *>(argExpression);
  if (idexpr) {
    return calculateIdExpression(idexpr, parentExpr);
  }
  auto sse = dynamic_cast<SubscriptExpression *>(argExpression);
  if (sse) {
    return calculateSubscriptExpression(sse, parentExpr);
  }
  auto fe = dynamic_cast<FunctionExpression *>(argExpression);
  if (fe) {
    return calculateFunctionExpression(fe, parentExpr);
  }
  return {};
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::analyseBuildDefinition(BuildDefinition *bd,
                                           Node *parentExpr,
                                           IdExpression *toResolve) {
  auto foundOurselves = false;
  std::vector<std::shared_ptr<InterpretNode>> tmp;
  for (auto &b : bd->stmts | std::ranges::views::reverse) {
    if (b->equals(parentExpr)) {
      foundOurselves = true;
      continue;
    }
    if (!foundOurselves) {
      continue;
    }
    auto *assignment = dynamic_cast<AssignmentStatement *>(b.get());
    if (!assignment) {
      auto fullEval = this->fullEval(b.get(), toResolve);
      tmp.insert(tmp.end(), fullEval.begin(), fullEval.end());
      continue;
    }
    auto *lhs = dynamic_cast<IdExpression *>(assignment->lhs.get());
    if (!lhs || lhs->id != toResolve->id) {
      auto fullEval = this->fullEval(b.get(), toResolve);
      tmp.insert(tmp.end(), fullEval.begin(), fullEval.end());
      continue;
    }
    auto others = this->abstractEval(b.get(), assignment->rhs.get());
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
  for (auto &b : its->stmts | std::ranges::views::reverse) {
    if (b->equals(parentExpr)) {
      foundOurselves = true;
      continue;
    }
    if (!foundOurselves) {
      continue;
    }
    auto *assignment = dynamic_cast<AssignmentStatement *>(b.get());
    if (!assignment) {
      auto fullEval = this->fullEval(b.get(), toResolve);
      tmp.insert(tmp.end(), fullEval.begin(), fullEval.end());
      continue;
    }
    auto *lhs = dynamic_cast<IdExpression *>(assignment->lhs.get());
    if (!lhs || lhs->id != toResolve->id) {
      auto fullEval = this->fullEval(b.get(), toResolve);
      tmp.insert(tmp.end(), fullEval.begin(), fullEval.end());
      continue;
    }
    auto others = this->abstractEval(b.get(), assignment->rhs.get());
    if (assignment->op == AssignmentOperator::Equals) {
      others.insert(others.end(), tmp.begin(), tmp.end());
      return others;
    }
    tmp.insert(tmp.end(), others.begin(), others.end());
  }
  auto idx = 0;
  for (auto b : its->ids) {
    auto *idexpr = dynamic_cast<IdExpression *>(b.get());
    if (!idexpr || idexpr->id != toResolve->id) {
      idx++;
      continue;
    }
    auto vals = this->abstractEval(parentExpr->parent, its->expression.get());
    vals.insert(vals.end(), tmp.begin(), tmp.end());
    if (its->ids.size() == 1) {
      std::vector<std::shared_ptr<InterpretNode>> normalized;
      for (auto node : vals) {
        auto al = dynamic_cast<ArrayLiteral *>(node->node);
        if (!al) {
          normalized.emplace_back(node);
          continue;
        }
        for (auto args : al->args) {
          auto tmp2 = this->abstractEval(its, args.get());
          normalized.insert(normalized.end(), tmp2.begin(), tmp2.end());
        }
      }
      return normalized;
    }
    std::vector<std::shared_ptr<InterpretNode>> ret;
    for (auto a : vals) {
      auto dictNode = dynamic_cast<DictionaryLiteral *>(a->node);
      if (!dictNode) {
        continue;
      }
      for (auto kvi : dictNode->values) {
        auto kviN = dynamic_cast<KeyValueItem *>(kvi.get());
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
    for (auto b : block | std::ranges::views::reverse) {
      if (b->equals(parentExpr)) {
        foundOurselves = true;
        continue;
      }
      if (!foundOurselves) {
        continue;
      }
      auto *assignment = dynamic_cast<AssignmentStatement *>(b.get());
      if (!assignment) {
        auto fullEval = this->fullEval(b.get(), toResolve);
        tmp.insert(tmp.end(), fullEval.begin(), fullEval.end());
        continue;
      }
      auto *lhs = dynamic_cast<IdExpression *>(assignment->lhs.get());
      if (!lhs || lhs->id != toResolve->id) {
        auto fullEval = this->fullEval(b.get(), toResolve);
        tmp.insert(tmp.end(), fullEval.begin(), fullEval.end());
        continue;
      }
      auto others = this->abstractEval(b.get(), assignment->rhs.get());
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
  auto parent = parentExpr->parent;
  auto bd = dynamic_cast<BuildDefinition *>(parent);
  if (bd) {
    return analyseBuildDefinition(bd, parentExpr, toResolve);
  }
  auto its = dynamic_cast<IterationStatement *>(parent);
  if (its) {
    return analyseIterationStatement(its, parentExpr, toResolve);
  }
  auto sst = dynamic_cast<SelectionStatement *>(parent);
  if (sst) {
    return analyseSelectionStatement(sst, parentExpr, toResolve);
  }

  return {};
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::evalStatement(Node *b, IdExpression *toResolve) {
  auto ass = dynamic_cast<AssignmentStatement *>(b);
  if (!ass) {
    return this->fullEval(b, toResolve);
  }
  auto lhs = dynamic_cast<IdExpression *>(ass->lhs.get());
  if (!lhs || lhs->id != toResolve->id) {
    return this->fullEval(b, toResolve);
  }
  return this->abstractEval(ass, ass->rhs.get());
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::fullEval(Node *stmt, IdExpression *toResolve) {
  std::vector<std::shared_ptr<InterpretNode>> ret;
  auto bd = dynamic_cast<BuildDefinition *>(stmt);
  if (bd) {
    for (auto &b : bd->stmts | std::ranges::views::reverse) {
      auto evaled = this->evalStatement(b.get(), toResolve);
      ret.insert(ret.end(), evaled.begin(), evaled.end());
    }
  }
  auto its = dynamic_cast<IterationStatement *>(stmt);
  if (its) {
    for (auto &b : its->stmts | std::ranges::views::reverse) {
      auto evaled = this->evalStatement(b.get(), toResolve);
      ret.insert(ret.end(), evaled.begin(), evaled.end());
    }
    for (auto b : its->ids) {
      auto idExpr = dynamic_cast<IdExpression *>(b.get());
      if (!idExpr || idExpr->id != toResolve->id) {
        continue;
      }
      auto evaled = this->evalStatement(b.get(), toResolve);
      ret.insert(ret.end(), evaled.begin(), evaled.end());
    }
  }
  auto sst = dynamic_cast<SelectionStatement *>(stmt);
  if (sst) {
    for (auto &block : sst->blocks | std::ranges::views::reverse) {
      for (auto b : block | std::ranges::views::reverse) {
        auto evaled = this->evalStatement(b.get(), toResolve);
        ret.insert(ret.end(), evaled.begin(), evaled.end());
      }
    }
  }
  return ret;
}

void PartialInterpreter::addToArrayConcatenated(
    ArrayLiteral *arr, std::string contents, std::string sep, bool literalFirst,
    std::vector<std::shared_ptr<InterpretNode>> &ret) {
  for (auto arrArg : arr->args) {
    auto asStr = dynamic_cast<StringLiteral *>(arrArg.get());
    if (!asStr) {
      continue;
    }
    auto full = literalFirst ? (contents + sep + asStr->id)
                             : (asStr->id + sep + contents);
    ret.emplace_back(std::make_shared<ArtificialStringNode>(full));
  }
}

void PartialInterpreter::abstractEvalComputeBinaryExpr(
    InterpretNode *l, InterpretNode *r, std::string sep,
    std::vector<std::shared_ptr<InterpretNode>> &ret) {
  auto lnode = l->node;
  auto sll = dynamic_cast<StringLiteral *>(lnode);
  auto rnode = r->node;
  auto slr = dynamic_cast<StringLiteral *>(rnode);
  if (sll && slr) {
    std::string str = sll->id + sep + slr->id;
    ret.emplace_back(std::make_shared<ArtificialStringNode>(str));
    return;
  }
  auto arrR = dynamic_cast<ArrayLiteral *>(rnode);
  if (sll && arrR) {
    for (auto arrArg : arrR->args) {
      auto argSL = dynamic_cast<StringLiteral *>(arrArg.get());
      if (argSL) {
        ret.emplace_back(
            std::make_shared<ArtificialStringNode>(sll->id + sep + argSL->id));
      }
      auto argAL = dynamic_cast<ArrayLiteral *>(arrArg.get());
      if (argAL) {
        addToArrayConcatenated(argAL, sll->id, sep, true, ret);
      }
    }
    return;
  }
  auto arrL = dynamic_cast<ArrayLiteral *>(lnode);
  if (slr && arrL) {
    for (auto arrArg : arrL->args) {
      auto argSL = dynamic_cast<StringLiteral *>(arrArg.get());
      if (argSL) {
        ret.emplace_back(
            std::make_shared<ArtificialStringNode>(argSL->id + sep + slr->id));
      }
      auto argAL = dynamic_cast<ArrayLiteral *>(arrArg.get());
      if (argAL) {
        addToArrayConcatenated(argAL, slr->id, sep, false, ret);
      }
    }
    return;
  }
  auto ldict = dynamic_cast<DictionaryLiteral *>(lnode);
  auto rdict = dynamic_cast<DictionaryLiteral *>(rnode);
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
  auto sep = be->op == BinaryOperator::Div ? "/" : "";
  for (auto l : lhs) {
    for (auto r : rhs) {
      abstractEvalComputeBinaryExpr(l.get(), r.get(), sep, ret);
    }
  }
  return ret;
}

void PartialInterpreter::abstractEvalComputeSubscriptExtractDictArray(
    ArrayLiteral *arr, StringLiteral *sl,
    std::vector<std::shared_ptr<InterpretNode>> &ret) {
  for (auto a : arr->args) {
    auto dict = dynamic_cast<DictionaryLiteral *>(a.get());
    if (!dict) {
      continue;
    }
    for (auto k : dict->values) {
      auto kvi = dynamic_cast<KeyValueItem *>(k.get());
      if (!kvi) {
        continue;
      }
      auto name = kvi->getKeyName();
      if (name != sl->id) {
        continue;
      }
      auto kviValue = dynamic_cast<StringLiteral *>(kvi->value.get());
      if (kviValue && kviValue->id == sl->id) {
        ret.emplace_back(std::make_shared<StringNode>(kviValue));
      }
    }
  }
}

void PartialInterpreter::abstractEvalComputeSubscript(
    InterpretNode *i, InterpretNode *o,
    std::vector<std::shared_ptr<InterpretNode>> &ret) {
  auto arr = dynamic_cast<ArrayLiteral *>(o->node);
  auto idx = dynamic_cast<IntegerLiteral *>(i->node);
  if (arr && idx && idx->valueAsInt < arr->args.size()) {
    auto nodeAtIdx = arr->args[idx->valueAsInt];
    auto atIdxSL = dynamic_cast<StringLiteral *>(nodeAtIdx.get());
    if (atIdxSL) {
      ret.emplace_back(std::make_shared<StringNode>(atIdxSL));
    }
    auto atIdxAL = dynamic_cast<ArrayLiteral *>(nodeAtIdx.get());
    if (atIdxAL) {
      for (auto a2 : atIdxAL->args) {
        auto asStr = dynamic_cast<StringLiteral *>(atIdxAL);
        if (asStr) {
          ret.emplace_back(std::make_shared<StringNode>(asStr));
        }
      }
    }
    return;
  }
  auto dict = dynamic_cast<DictionaryLiteral *>(o->node);
  auto sl = dynamic_cast<StringLiteral *>(i->node);
  if (dict && sl) {
    for (auto k : dict->values) {
      auto kvi = dynamic_cast<KeyValueItem *>(k.get());
      if (!kvi) {
        continue;
      }
      auto name = kvi->getKeyName();
      if (name != sl->id) {
        continue;
      }
      auto kviValue = dynamic_cast<StringLiteral *>(kvi->value.get());
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
  for (auto o : outer) {
    for (auto i : inner) {
      this->abstractEvalComputeSubscript(i.get(), o.get(), ret);
    }
    auto dictN = dynamic_cast<DictionaryLiteral *>(o->node);
    if (!dictN || !inner.empty()) {
      continue;
    }
    for (auto k : dictN->values) {
      auto kvi = dynamic_cast<KeyValueItem *>(k.get());
      if (!kvi) {
        continue;
      }
      auto kviValue = dynamic_cast<StringLiteral *>(kvi->value.get());
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
  for (auto o : objs) {
    auto sl1 = dynamic_cast<StringLiteral *>(o->node);
    if (sl1) {
      auto parts = split(sl1->id, splitAt);
      if (idxI < parts.size()) {
        ret.emplace_back(std::make_shared<ArtificialStringNode>(parts[idxI]));
      }
      continue;
    }
    auto arr = dynamic_cast<ArrayLiteral *>(o->node);
    if (!arr) {
      continue;
    }
    for (auto arrArg : arr->args) {
      auto sl1 = dynamic_cast<StringLiteral *>(arrArg.get());
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
PartialInterpreter::abstractEvalMethod(MethodExpression *me, Node *parentStmt) {
  auto meobj = this->abstractEval(parentStmt, me->obj.get());
  auto meid = dynamic_cast<IdExpression *>(me->id.get());
  std::vector<std::shared_ptr<InterpretNode>> ret;
  if (!meid) {
    return ret;
  }
  for (auto r : meobj) {
    std::vector<std::string> strValues;
    auto arr = dynamic_cast<ArrayLiteral *>(r->node);
    if (arr) {
      for (auto a : arr->args) {
        auto sl = dynamic_cast<StringLiteral *>(a.get());
        if (sl) {
          strValues.push_back(sl->id);
        }
      }
    }
    auto sl = dynamic_cast<StringLiteral *>(r->node);
    if (sl) {
      strValues.emplace_back(sl->id);
    }
    if (meid->id != "keys") {
      for (const auto &s : strValues) {
        ret.emplace_back(
            std::make_shared<ArtificialStringNode>(applyMethod(s, meid->id)));
      }
    }
    auto dictionaryLiteral = dynamic_cast<DictionaryLiteral *>(r->node);
    if (!dictionaryLiteral || meid->id != "keys") {
      continue;
    }
    for (auto kvin : dictionaryLiteral->values) {
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
    SubscriptExpression *se, IdExpression *outerObj, Node *parentStmt) {
  auto objs = this->resolveArrayOrDict(parentStmt, outerObj);
  std::vector<std::shared_ptr<InterpretNode>> ret;
  for (auto r : objs) {
    auto arr = dynamic_cast<ArrayLiteral *>(r->node);
    auto idx = dynamic_cast<IntegerLiteral *>(se->inner.get());
    if (arr && idx && idx->valueAsInt < arr->args.size()) {
      auto nodeAtIdx = arr->args[idx->valueAsInt];
      auto atIdxSL = dynamic_cast<StringLiteral *>(nodeAtIdx.get());
      if (atIdxSL) {
        ret.push_back(std::make_shared<StringNode>(atIdxSL));
        continue;
      }
      auto atIdxAL = dynamic_cast<ArrayLiteral *>(nodeAtIdx.get());
      if (!atIdxAL) {
        continue;
      }
      for (auto a2 : atIdxAL->args) {
        auto asSL = dynamic_cast<StringLiteral *>(a2.get());
        if (asSL) {
          ret.push_back(std::make_shared<StringNode>(asSL));
        }
      }
      continue;
    }
    if (dynamic_cast<StringNode *>(r.get()) ||
        dynamic_cast<ArtificialStringNode *>(r.get())) {
      ret.emplace_back(r);
      continue;
    }
    auto sl = dynamic_cast<StringLiteral *>(se->inner.get());
    auto dict = dynamic_cast<DictionaryLiteral *>(r->node);
    if (sl && dict) {
      for (auto k : dict->values) {
        auto kvi = dynamic_cast<KeyValueItem *>(k.get());
        if (!kvi) {
          continue;
        }
        auto name = kvi->getKeyName();
        if (name != sl->id) {
          continue;
        }
        auto kviValue = dynamic_cast<StringLiteral *>(kvi->value.get());
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
PartialInterpreter::abstractEvalGetMethodCall(MethodExpression *me,
                                              IdExpression *meobj,
                                              ArgumentList *al,
                                              Node *parentStmt) {
  std::vector<std::shared_ptr<InterpretNode>> ret;
  auto objs = this->resolveArrayOrDict(parentStmt, meobj);
  for (auto r : objs) {
    auto arr = dynamic_cast<ArrayLiteral *>(r->node);
    auto idx = dynamic_cast<IntegerLiteral *>(al->args[0].get());
    if (arr && idx && idx->valueAsInt < arr->args.size()) {
      auto atIdx =
          dynamic_cast<StringLiteral *>(arr->args[idx->valueAsInt].get());
      if (atIdx) {
        ret.emplace_back(std::make_shared<StringNode>(atIdx));
      }
      continue;
    } else if (dynamic_cast<StringNode *>(r.get())) {
      ret.emplace_back(std::make_shared<StringNode>(r->node));
      continue;
    }
    auto sl = dynamic_cast<StringLiteral *>(al->args[0].get());
    auto dict = dynamic_cast<DictionaryLiteral *>(r->node);
    if (sl && dict) {
      for (auto k : dict->values) {
        auto kvi = dynamic_cast<KeyValueItem *>(k.get());
        if (!kvi) {
          continue;
        }
        auto name = kvi->getKeyName();
        if (name != sl->id) {
          continue;
        }
        auto kviValue = dynamic_cast<StringLiteral *>(kvi->value.get());
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
  auto firstArg = al->args[0].get();
  std::vector<std::shared_ptr<InterpretNode>> ret;

  for (auto a : al->args) {
    if (dynamic_cast<ArrayLiteral *>(firstArg)) {
      ret.emplace_back(std::make_shared<ArrayNode>(a.get()));
    } else if (dynamic_cast<DictionaryLiteral *>(firstArg)) {
      ret.emplace_back(std::make_shared<DictNode>(a.get()));
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
    SubscriptExpression *se, Node *parentStmt) {
  auto inner = se->inner.get();
  auto outer = se->outer.get();
  if ((dynamic_cast<StringLiteral *>(inner) ||
       dynamic_cast<IntegerLiteral *>(inner)) &&
      dynamic_cast<IdExpression *>(outer)) {
    return abstractEvalSimpleSubscriptExpression(
        se, dynamic_cast<IdExpression *>(outer), parentStmt);
  }
  auto idx = dynamic_cast<IntegerLiteral *>(inner);
  auto outerME = dynamic_cast<MethodExpression *>(outer);
  if (idx && outerME) {
    auto meId = dynamic_cast<IdExpression *>(outerME->id.get());
    if (!meId || meId->id != "split") {
      return this->abstractEvalSubscriptExpression(se, parentStmt);
    }
    auto al = dynamic_cast<ArgumentList *>(outerME->args.get());
    if (!al || al->args.empty()) {
      return this->abstractEvalSubscriptExpression(se, parentStmt);
    }
    auto sl = dynamic_cast<StringLiteral *>(al->args[0].get());
    if (sl) {
      return this->abstractEvalSplitWithSubscriptExpression(idx, sl, outerME,
                                                            parentStmt);
    }
  }
  return this->abstractEvalSubscriptExpression(se, parentStmt);
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
  for (auto string : firstArray) {
    auto o1 = dynamic_cast<StringLiteral *>(string->node);
    if (!o1) {
      continue;
    }
    for (auto combination : restCombinations) {
      auto sl = dynamic_cast<StringLiteral *>(combination->node);
      if (!sl) {
        continue;
      }
      combinations.emplace_back(
          std::make_shared<ArtificialStringNode>(o1->id + "/" + sl->id));
    }
  }
  return combinations;
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::abstractEvalFunction(FunctionExpression *fe,
                                         Node *parentStmt) {
  auto al = dynamic_cast<ArgumentList *>(fe->args.get());
  if (!al) {
    return {};
  }
  auto feid = dynamic_cast<IdExpression *>(fe->id.get());
  if (!feid) {
    return {};
  }
  auto fnid = feid->id;
  if (fnid == "join_paths") {
    std::vector<std::vector<std::shared_ptr<InterpretNode>>> items;
    for (auto a : al->args) {
      if (dynamic_cast<KeywordItem *>(a.get())) {
        continue;
      }
      items.emplace_back(this->abstractEval(parentStmt, a.get()));
    }
    return allAbstractStringCombinations(items);
  }
  if (fnid != "get_option") {
    return {};
  }
  auto first = dynamic_cast<StringLiteral *>(al->args[0].get());
  if (!first) {
    return {};
  }
  auto option = this->options.findOption(first->id);
  if (!option) {
    return {};
  }
  std::vector<std::shared_ptr<InterpretNode>> ret;
  auto co = dynamic_cast<ComboOption *>(option.get());
  if (co) {
    for (auto val : co->values) {
      ret.emplace_back(std::make_shared<ArtificialStringNode>(val));
    }
  }
  auto ao = dynamic_cast<ArrayOption *>(option.get());
  if (ao) {
    for (auto val : ao->choices) {
      ret.emplace_back(std::make_shared<ArtificialStringNode>(val));
    }
  }
  return ret;
}

std::vector<std::shared_ptr<InterpretNode>>
PartialInterpreter::abstractEval(Node *parentStmt, Node *toEval) {
  auto dict = dynamic_cast<DictionaryLiteral *>(toEval);
  if (dict) {
    return {std::make_shared<DictNode>(dict)};
  }
  auto arrL = dynamic_cast<ArrayLiteral *>(toEval);
  if (arrL) {
    return {std::make_shared<ArrayNode>(arrL)};
  }
  auto slL = dynamic_cast<StringLiteral *>(toEval);
  if (slL) {
    return {std::make_shared<StringNode>(slL)};
  }
  auto ilL = dynamic_cast<IntegerLiteral *>(toEval);
  if (ilL) {
    return {std::make_shared<IntNode>(ilL)};
  }
  auto be = dynamic_cast<BinaryExpression *>(toEval);
  if (be) {
    return abstractEvalBinaryExpression(be, parentStmt);
  }
  auto idexpr = dynamic_cast<IdExpression *>(toEval);
  if (idexpr) {
    return resolveArrayOrDict(parentStmt, idexpr);
  }
  auto me = dynamic_cast<MethodExpression *>(toEval);
  if (me && me->args) {
    auto meid = dynamic_cast<IdExpression *>(me->id.get());
    if (meid->id == "format" && me->args) {
      auto strs = calculateStringFormatMethodCall(
          me, dynamic_cast<ArgumentList *>(me->args.get()), parentStmt);
      std::vector<std::shared_ptr<InterpretNode>> ret;
      ret.reserve(strs.size());
      for (auto str : strs) {
        ret.emplace_back(std::make_shared<ArtificialStringNode>(str));
      }
      return ret;
    }
    if (!meid || meid->id != "get") {
      goto next;
    }
    auto meObj = dynamic_cast<IdExpression *>(me->obj.get());
    auto al = dynamic_cast<ArgumentList *>(me->args.get());
    if (!al || al->args.empty()) {
      goto next;
    }
    return this->abstractEvalGetMethodCall(me, meObj, al, parentStmt);
  }
next:
  if (me && isValidMethod(me)) {
    return this->abstractEvalMethod(me, parentStmt);
  }
  auto ce = dynamic_cast<ConditionalExpression *>(toEval);
  if (ce) {
    auto ret = this->abstractEval(parentStmt, ce->ifTrue.get());
    auto ifFalse = this->abstractEval(parentStmt, ce->ifFalse.get());
    ret.insert(ret.end(), ifFalse.begin(), ifFalse.end());
    return ret;
  }
  auto sse = dynamic_cast<SubscriptExpression *>(toEval);
  if (sse) {
    return this->abstractEvalGenericSubscriptExpression(sse, parentStmt);
  }
  auto fe = dynamic_cast<FunctionExpression *>(toEval);
  if (fe && isValidFunction(fe)) {
    return this->abstractEvalFunction(fe, parentStmt);
  }
  auto ass = dynamic_cast<AssignmentStatement *>(toEval);
  if (ass) {
    return this->abstractEval(parentStmt, ass->rhs.get());
  }
  return {};
}

bool isValidFunction(FunctionExpression *fe) {
  std::set<std::string> funcs{"join_paths", "get_option"};
  return funcs.contains(fe->functionName());
}

bool isValidMethod(MethodExpression *me) {
  auto meid = dynamic_cast<IdExpression *>(me->id.get());
  if (!meid) {
    return false;
  }
  std::set<std::string> names{"underscorify", "to_lower", "to_upper", "strip",
                              "keys"};
  return names.contains(meid->id);
}

std::string applyMethod(std::string varname, std::string name) {
  if (name == "underscorify") {
    std::string ret;
    ret.reserve(varname.size());
    for (auto v : varname) {
      if (std::isalnum(v) != 0) {
        ret.push_back(v);
      } else {
        ret.push_back('_');
      }
    }
    return ret;
  }
  if (name == "to_lower") {
    std::string data = varname;
    std::transform(data.begin(), data.end(), data.begin(),
                   [](unsigned char chr) { return std::tolower(chr); });
    return data;
  }
  if (name == "to_upper") {
    std::string data = varname;
    std::transform(data.begin(), data.end(), data.begin(),
                   [](unsigned char chr) { return std::toupper(chr); });
    return data;
  }
  if (name == "strip") {
    auto data = varname;
    trim(data);
    return data;
  }
  assert(false);
}
