#pragma once

#include "node.hpp"
#include "optionstate.hpp"

#include <memory>
#include <string>
#include <utility>
#include <vector>

std::vector<std::string> guessSetVariable(FunctionExpression *fe,
                                          OptionState &opts);
std::vector<std::string> guessSetVariable(FunctionExpression *fe,
                                          const std::string &kwargName,
                                          OptionState &opts);
std::vector<std::string> guessGetVariableMethod(MethodExpression *me,
                                                OptionState &opts);

class InterpretNode {
public:
  const Node *node;
  bool deleteNode{};

  virtual ~InterpretNode() {
    if (deleteNode) {
      delete this->node;
    }
  };

  explicit InterpretNode(const Node *node) : node(node) {}

  InterpretNode() = default;
};

class ArrayNode : public InterpretNode {
  using InterpretNode::InterpretNode;
};

class StringNode : public InterpretNode {
  using InterpretNode::InterpretNode;
};

class DictNode : public InterpretNode {
  using InterpretNode::InterpretNode;
};

class IntNode : public InterpretNode {
  using InterpretNode::InterpretNode;
};

class ArtificialStringNode : public InterpretNode {
public:
  explicit ArtificialStringNode(std::string str)
      : InterpretNode(new StringLiteral(std::move(str))) {
    this->deleteNode = true;
  }
};

class ArtificialArrayNode : public InterpretNode {
public:
  explicit ArtificialArrayNode(
      const std::vector<std::shared_ptr<InterpretNode>> &args) {
    auto *arr = new ArrayLiteral({});
    this->node = arr;
    for (const auto &arg : args) {
      const auto *asString = dynamic_cast<const StringLiteral *>(arg->node);
      auto copy = std::make_shared<StringLiteral>(asString->id);
      arr->args.push_back(copy);
    }
    this->deleteNode = true;
  }
};

class PartialInterpreter {
  OptionState &options;

public:
  explicit PartialInterpreter(OptionState &options) : options(options) {}

  std::vector<std::string> calculate(const Node *parent,
                                     const Node *exprToCalculate);

private:
  std::vector<std::shared_ptr<InterpretNode>> keepAlives;
  std::vector<std::string>
  calculateStringFormatMethodCall(const MethodExpression *me,
                                  const ArgumentList *al,
                                  const Node *parentExpr);
  std::vector<std::string>
  calculateBinaryExpression(const Node *parentExpr, const BinaryExpression *be);
  std::vector<std::string> calculateGetMethodCall(const ArgumentList *al,
                                                  const IdExpression *meObj,
                                                  const Node *parentExpr);
  std::vector<std::string> calculateIdExpression(const IdExpression *idExpr,
                                                 const Node *parentExpr);
  std::vector<std::string>
  calculateSubscriptExpression(const SubscriptExpression *sse,
                               const Node *parentExpr);
  std::vector<std::string>
  calculateFunctionExpression(const FunctionExpression *fe,
                              const Node *parentExpr);
  std::vector<std::string> calculateExpression(const Node *parentExpr,
                                               const Node *argExpression);
  static void
  calculateEvalSubscriptExpression(const std::shared_ptr<InterpretNode> &inner,
                                   const std::shared_ptr<InterpretNode> &outer,
                                   std::vector<std::string> &ret);
  std::vector<std::shared_ptr<InterpretNode>>
  analyseBuildDefinition(const BuildDefinition *bd, const Node *parentExpr,
                         const IdExpression *toResolve);
  std::vector<std::shared_ptr<InterpretNode>>
  analyseIterationStatement(const IterationStatement *its,
                            const Node *parentExpr,
                            const IdExpression *toResolve);
  std::vector<std::shared_ptr<InterpretNode>>
  analyseSelectionStatement(const SelectionStatement *sst,
                            const Node *parentExpr,
                            const IdExpression *toResolve);
  std::vector<std::shared_ptr<InterpretNode>>
  abstractEval(const Node *parentStmt, const Node *toEval);
  std::vector<std::shared_ptr<InterpretNode>>
  resolveArrayOrDict(const Node *parentExpr, const IdExpression *toResolve);
  std::vector<std::shared_ptr<InterpretNode>>
  fullEval(const Node *stmt, const IdExpression *toResolve);
  std::vector<std::shared_ptr<InterpretNode>>
  evalStatement(const Node *stmt, const IdExpression *toResolve);
  static void
  addToArrayConcatenated(const ArrayLiteral *arr, const std::string &contents,
                         const std::string &sep, bool literalFirst,
                         std::vector<std::shared_ptr<InterpretNode>> &ret);
  void abstractEvalComputeBinaryExpr(
      const InterpretNode *left, const InterpretNode *right,
      const std::string &sep, std::vector<std::shared_ptr<InterpretNode>> &ret);
  std::vector<std::shared_ptr<InterpretNode>>
  abstractEvalBinaryExpression(const BinaryExpression *be,
                               const Node *parentStmt);
  static void abstractEvalComputeSubscriptExtractDictArray(
      const ArrayLiteral *arr, const StringLiteral *sl,
      std::vector<std::shared_ptr<InterpretNode>> &ret);
  void abstractEvalComputeSubscript(
      const InterpretNode *inner, const InterpretNode *outer,
      std::vector<std::shared_ptr<InterpretNode>> &ret);
  std::vector<std::shared_ptr<InterpretNode>>
  abstractEvalSubscriptExpression(const SubscriptExpression *sse,
                                  const Node *parentStmt);
  std::vector<std::shared_ptr<InterpretNode>>
  abstractEvalMethod(const MethodExpression *me, const Node *parentStmt);
  std::vector<std::shared_ptr<InterpretNode>>
  abstractEvalSplitWithSubscriptExpression(const IntegerLiteral *idx,
                                           const StringLiteral *sl,
                                           const MethodExpression *outerMe,
                                           const Node *parentStmt);
  std::vector<std::shared_ptr<InterpretNode>>
  abstractEvalSimpleSubscriptExpression(const SubscriptExpression *sse,
                                        const IdExpression *outerObj,
                                        const Node *parentStmt);
  std::vector<std::shared_ptr<InterpretNode>>
  abstractEvalGetMethodCall(const MethodExpression *me,
                            const IdExpression *meobj, const ArgumentList *al,
                            const Node *parentStmt);
  std::vector<std::shared_ptr<InterpretNode>>
  abstractEvalArrayLiteral(const ArrayLiteral *al, const Node *toEval,
                           const Node *parentStmt);
  std::vector<std::shared_ptr<InterpretNode>>
  abstractEvalGenericSubscriptExpression(const SubscriptExpression *sse,
                                         const Node *parentStmt);
  std::vector<std::shared_ptr<InterpretNode>>
  abstractEvalFunction(const FunctionExpression *fe, const Node *parentStmt);
  std::vector<std::shared_ptr<InterpretNode>>
  abstractEvalSplitByWhitespace(const IntegerLiteral *idx,
                                const MethodExpression *outerMe,
                                const Node *parentStmt);
};
