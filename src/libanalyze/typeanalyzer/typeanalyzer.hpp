#pragma once

#include "function.hpp"
#include "mesonmetadata.hpp"
#include "mesontree.hpp"
#include "node.hpp"
#include "typenamespace.hpp"

#include <filesystem>
#include <memory>
#include <string>
#include <vector>

std::string joinTypes(std::vector<std::shared_ptr<Type>> types);

class TypeAnalyzer : public CodeVisitor {
public:
  TypeNamespace &ns;
  MesonTree *tree;
  MesonMetadata *metadata;

  TypeAnalyzer(TypeNamespace &ns, MesonMetadata *metadata, MesonTree *tree)
      : ns(ns), tree(tree), metadata(metadata) {}

  void visitArgumentList(ArgumentList *node) override;
  void visitArrayLiteral(ArrayLiteral *node) override;
  void visitAssignmentStatement(AssignmentStatement *node) override;
  void visitBinaryExpression(BinaryExpression *node) override;
  void visitBooleanLiteral(BooleanLiteral *node) override;
  void visitBuildDefinition(BuildDefinition *node) override;
  void visitConditionalExpression(ConditionalExpression *node) override;
  void visitDictionaryLiteral(DictionaryLiteral *node) override;
  void visitFunctionExpression(FunctionExpression *node) override;
  void visitIdExpression(IdExpression *node) override;
  void visitIntegerLiteral(IntegerLiteral *node) override;
  void visitIterationStatement(IterationStatement *node) override;
  void visitKeyValueItem(KeyValueItem *node) override;
  void visitKeywordItem(KeywordItem *node) override;
  void visitMethodExpression(MethodExpression *node) override;
  void visitSelectionStatement(SelectionStatement *node) override;
  void visitStringLiteral(StringLiteral *node) override;
  void visitSubscriptExpression(SubscriptExpression *node) override;
  void visitUnaryExpression(UnaryExpression *node) override;
  void visitErrorNode(ErrorNode *node) override;
  void visitBreakNode(BreakNode *node) override;
  void visitContinueNode(ContinueNode *node) override;

private:
  std::vector<std::filesystem::path> sourceFileStack;
  std::vector<std::vector<IdExpression *>> variablesNeedingUse;
  std::vector<std::vector<std::string>> foundVariables;
  void checkProjectCall(BuildDefinition *node);
  void checkDeadNodes(BuildDefinition *node);
  void applyDead(std::shared_ptr<Node> &lastAlive,
                 std::shared_ptr<Node> &firstDead,
                 std::shared_ptr<Node> &lastDead);
  void checkUnusedVariables();
  bool isDead(const std::shared_ptr<Node> &node);
  void checkDuplicateNodeKeys(DictionaryLiteral *node);
  void setFunctionCallTypes(FunctionExpression *node,
                            std::shared_ptr<Function> fn);
  void specialFunctionCallHandling(FunctionExpression *node,
                                   std::shared_ptr<Function> fn);
  void checkCall(FunctionExpression *node);
  void checkSetVariable(FunctionExpression *node, ArgumentList *al);
  void guessSetVariable(std::vector<std::shared_ptr<Node>> args,
                        FunctionExpression *node);
  void checkIfInLoop(Node *node, std::string str) const;
  void extractVoidAssignment(AssignmentStatement *node);
  void evaluateFullAssignment(AssignmentStatement *node,
                              IdExpression *lhsIdExpr);
  void evaluatePureAssignment(AssignmentStatement *node,
                              IdExpression *lhsIdExpr);
};
