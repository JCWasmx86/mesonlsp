#pragma once

#include "node.hpp"
#include "optionstate.hpp"

#include <string>
#include <utility>
#include <vector>

std::vector<std::string> guessSetVariable(FunctionExpression *fe,
                                          OptionState &opts);
std::vector<std::string> guessGetVariableMethod(MethodExpression *me,
                                                OptionState &opts);

class InterpretNode {
public:
  Node *node;
  bool deleteNode = false;

  virtual ~InterpretNode() {
    if (deleteNode) {
      delete this->node;
    }
  };

  InterpretNode(Node *node) : node(node) {}
};

class ArrayNode : public InterpretNode {
public:
  ArrayNode(Node *node) : InterpretNode(node) {}
};

class StringNode : public InterpretNode {
public:
  StringNode(Node *node) : InterpretNode(node) {}
};

class DictNode : public InterpretNode {
public:
  DictNode(Node *node) : InterpretNode(node) {}
};

class IntNode : public InterpretNode {
public:
  IntNode(Node *node) : InterpretNode(node) {}
};

class ArtificialStringNode : public InterpretNode {
public:
  ArtificialStringNode(std::string str)
      : InterpretNode(new StringLiteral(std::move(str))) {
    this->deleteNode = true;
  }
};

class PartialInterpreter {

  OptionState &options;

public:
  PartialInterpreter(OptionState &options) : options(options) {}

  std::vector<std::string> calculate(Node *parent, Node *exprToCalculate);

private:
  std::vector<std::string> calculateStringFormatMethodCall(MethodExpression *me,
                                                           ArgumentList *al,
                                                           Node *parentExpr);
  std::vector<std::string> calculateBinaryExpression(Node *parentExpr,
                                                     BinaryExpression *be);
  std::vector<std::string> calculateGetMethodCall(ArgumentList *al,
                                                  IdExpression *meObj,
                                                  Node *parentExpr);
  std::vector<std::string> calculateIdExpression(IdExpression *idExpr,
                                                 Node *parentExpr);
  std::vector<std::string>
  calculateSubscriptExpression(SubscriptExpression *sse, Node *parentExpr);
  std::vector<std::string> calculateFunctionExpression(FunctionExpression *fe,
                                                       Node *parentExpr);
  std::vector<std::string> calculateExpression(Node *parentExpr,
                                               Node *argExpression);
  void calculateEvalSubscriptExpression(std::shared_ptr<InterpretNode> i,
                                        std::shared_ptr<InterpretNode> o,
                                        std::vector<std::string> &ret);
  std::vector<std::shared_ptr<InterpretNode>>
  analyseBuildDefinition(BuildDefinition *bd, Node *parentExpr,
                         IdExpression *toResolve);
  std::vector<std::shared_ptr<InterpretNode>>
  analyseIterationStatement(IterationStatement *its, Node *parentExpr,
                            IdExpression *toResolve);
  std::vector<std::shared_ptr<InterpretNode>>
  analyseSelectionStatement(SelectionStatement *sst, Node *parentExpr,
                            IdExpression *toResolve);
  std::vector<std::shared_ptr<InterpretNode>> abstractEval(Node *parentStmt,
                                                           Node *toEval);
  std::vector<std::shared_ptr<InterpretNode>>
  resolveArrayOrDict(Node *parentExpr, IdExpression *toResolve);
  std::vector<std::shared_ptr<InterpretNode>> fullEval(Node *stmt,
                                                       IdExpression *toResolve);
  std::vector<std::shared_ptr<InterpretNode>>
  evalStatement(Node *b, IdExpression *toResolve);
  void addToArrayConcatenated(ArrayLiteral *arr, std::string contents,
                              std::string sep, bool literalFirst,
                              std::vector<std::shared_ptr<InterpretNode>> &ret);
  void abstractEvalComputeBinaryExpr(
      InterpretNode *l, InterpretNode *r, std::string sep,
      std::vector<std::shared_ptr<InterpretNode>> &ret);
  std::vector<std::shared_ptr<InterpretNode>>
  abstractEvalBinaryExpression(BinaryExpression *be, Node *parentStmt);
  void abstractEvalComputeSubscriptExtractDictArray(
      ArrayLiteral *arr, StringLiteral *sl,
      std::vector<std::shared_ptr<InterpretNode>> &ret);
  void abstractEvalComputeSubscript(
      InterpretNode *i, InterpretNode *o,
      std::vector<std::shared_ptr<InterpretNode>> &ret);
  std::vector<std::shared_ptr<InterpretNode>>
  abstractEvalSubscriptExpression(SubscriptExpression *sse, Node *parentStmt);
  std::vector<std::shared_ptr<InterpretNode>>
  abstractEvalMethod(MethodExpression *me, Node *parentStmt);
  std::vector<std::shared_ptr<InterpretNode>>
  abstractEvalSplitWithSubscriptExpression(IntegerLiteral *idx,
                                           StringLiteral *sl,
                                           MethodExpression *outerMe,
                                           Node *parentStmt);
  std::vector<std::shared_ptr<InterpretNode>>
  abstractEvalSimpleSubscriptExpression(SubscriptExpression *se,
                                        IdExpression *outerObj,
                                        Node *parentStmt);
  std::vector<std::shared_ptr<InterpretNode>>
  abstractEvalGetMethodCall(MethodExpression *me, IdExpression *meobj,
                            ArgumentList *al, Node *parentStmt);
  std::vector<std::shared_ptr<InterpretNode>>
  abstractEvalArrayLiteral(ArrayLiteral *al, Node *toEval, Node *parentStmt);
  std::vector<std::shared_ptr<InterpretNode>>
  abstractEvalGenericSubscriptExpression(SubscriptExpression *se,
                                         Node *parentStmt);
  std::vector<std::shared_ptr<InterpretNode>>
  abstractEvalFunction(FunctionExpression *fe, Node *parentStmt);
};
