#pragma once

#include "analysisoptions.hpp"
#include "function.hpp"
#include "mesonmetadata.hpp"
#include "mesontree.hpp"
#include "node.hpp"
#include "optionstate.hpp"
#include "scope.hpp"
#include "typenamespace.hpp"

#include <filesystem>
#include <memory>
#include <optional>
#include <string>
#include <utility>
#include <vector>

std::string joinTypes(const std::vector<std::shared_ptr<Type>> &types);

class TypeAnalyzer : public CodeVisitor {
public:
  const TypeNamespace &ns;
  MesonTree *tree;
  MesonMetadata *metadata;
  Scope scope;
  AnalysisOptions analysisOptions;
  OptionState options;

  TypeAnalyzer(const TypeNamespace &ns, MesonMetadata *metadata,
               MesonTree *tree, Scope scope, AnalysisOptions analysisOptions,
               OptionState options)
      : ns(ns), tree(tree), metadata(metadata), scope(scope),
        analysisOptions(analysisOptions), options(std::move(options)) {}

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
  std::vector<std::string> ignoreUnknownIdentifier;
  std::vector<std::map<std::string, std::vector<std::shared_ptr<Type>>>> stack;
  std::vector<std::map<std::string, std::vector<std::shared_ptr<Type>>>>
      overriddenVariables;
  void checkProjectCall(BuildDefinition *node);
  void checkDeadNodes(BuildDefinition *node);
  void applyDead(std::shared_ptr<Node> &lastAlive,
                 std::shared_ptr<Node> &firstDead,
                 std::shared_ptr<Node> &lastDead) const;
  void checkUnusedVariables();
  bool isDead(const std::shared_ptr<Node> &node);
  void checkDuplicateNodeKeys(DictionaryLiteral *node);
  void setFunctionCallTypes(FunctionExpression *node,
                            std::shared_ptr<Function> fn);
  void specialFunctionCallHandling(FunctionExpression *node,
                                   std::shared_ptr<Function> fn);
  void checkCall(Node *node);
  void checkSetVariable(FunctionExpression *node, ArgumentList *al);
  void guessSetVariable(std::vector<std::shared_ptr<Node>> args,
                        FunctionExpression *node);
  void checkIfInLoop(Node *node, std::string str) const;
  void extractVoidAssignment(AssignmentStatement *node) const;
  void evaluateFullAssignment(AssignmentStatement *node,
                              IdExpression *lhsIdExpr);
  void evaluatePureAssignment(AssignmentStatement *node,
                              IdExpression *lhsIdExpr);
  std::vector<std::shared_ptr<Type>>
  evalAssignment(AssignmentOperator op, std::vector<std::shared_ptr<Type>> lhs,
                 std::vector<std::shared_ptr<Type>> rhs);
  void evalAssignmentTypes(std::shared_ptr<Type> l, std::shared_ptr<Type> r,
                           AssignmentOperator op,
                           std::vector<std::shared_ptr<Type>> *newTypes);
  std::optional<std::shared_ptr<Type>> evalPlusEquals(std::shared_ptr<Type> l,
                                                      std::shared_ptr<Type> r);
  void applyToStack(std::string name, std::vector<std::shared_ptr<Type>> types);
  void checkIdentifier(IdExpression *node) const;
  void registerNeedForUse(IdExpression *node);
  void analyseIterationStatementSingleIdentifier(IterationStatement *node);
  void analyseIterationStatementTwoIdentifiers(IterationStatement *node);
  bool checkCondition(Node *condition);
  bool isSpecial(std::vector<std::shared_ptr<Type>> &types);
  void checkIfSpecialComparison(MethodExpression *me, StringLiteral *sl);
  std::vector<std::shared_ptr<Type>> evalBinaryExpression(
      BinaryOperator op, std::vector<std::shared_ptr<Type>> lhs,
      std::vector<std::shared_ptr<Type>> rhs, unsigned int *nErrors);
  void enterSubdir(FunctionExpression *node);
  void registerUsed(const std::string &id);
  std::vector<std::shared_ptr<Type>> evalStack(std::string &name);
  bool ignoreIdExpression(IdExpression *node);
  bool isKnownId(IdExpression *id);
  bool guessMethod(MethodExpression *node, const std::string &methodName,
                   std::vector<std::shared_ptr<Type>> &ownResultTypes);
  bool findMethod(MethodExpression *node, std::string methodName, int *nAny,
                  int *bits,
                  std::vector<std::shared_ptr<Type>> &ownResultTypes);
  void checkNoEffect(Node *node) const;
  void checkFormat(StringLiteral *sl,
                   const std::vector<std::shared_ptr<Node>> &args);
  void
  checkKwargsAfterPositionalArguments(std::vector<std::shared_ptr<Node>> args);
  void checkKwargs(std::shared_ptr<Function> func,
                   std::vector<std::shared_ptr<Node>> args, Node *node);
  void checkArgTypes(std::shared_ptr<Function> func,
                     std::vector<std::shared_ptr<Node>> args, Node *node);
  void checkTypes(std::shared_ptr<Node> arg,
                  const std::vector<std::shared_ptr<Type>> &expectedTypes,
                  const std::vector<std::shared_ptr<Type>> &givenTypes);
  bool atleastPartiallyCompatible(
      const std::vector<std::shared_ptr<Type>> &expectedTypes,
      const std::vector<std::shared_ptr<Type>> &givenTypes);
  bool compatible(std::shared_ptr<Type> given, std::shared_ptr<Type> expected);
};
