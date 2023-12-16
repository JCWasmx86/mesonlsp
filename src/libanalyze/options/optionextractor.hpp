#pragma once

#include "mesonoption.hpp"
#include "node.hpp"
#include <memory>
#include <vector>

class OptionExtractor : public CodeVisitor {
public:
  std::vector<std::shared_ptr<MesonOption>> options;
  void visitArgumentList(ArgumentList *node);
  void visitArrayLiteral(ArrayLiteral *node);
  void visitAssignmentStatement(AssignmentStatement *node);
  void visitBinaryExpression(BinaryExpression *node);
  void visitBooleanLiteral(BooleanLiteral *node);
  void visitBuildDefinition(BuildDefinition *node);
  void visitConditionalExpression(ConditionalExpression *node);
  void visitDictionaryLiteral(DictionaryLiteral *node);
  void visitFunctionExpression(FunctionExpression *node);
  void visitIdExpression(IdExpression *node);
  void visitIntegerLiteral(IntegerLiteral *node);
  void visitIterationStatement(IterationStatement *node);
  void visitKeyValueItem(KeyValueItem *node);
  void visitKeywordItem(KeywordItem *node);
  void visitMethodExpression(MethodExpression *node);
  void visitSelectionStatement(SelectionStatement *node);
  void visitStringLiteral(StringLiteral *node);
  void visitSubscriptExpression(SubscriptExpression *node);
  void visitUnaryExpression(UnaryExpression *node);
  void visitErrorNode(ErrorNode *node);
  void visitBreakNode(BreakNode *node);
  void visitContinueNode(ContinueNode *node);
};
