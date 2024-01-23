#pragma once

#include "mesonmetadata.hpp"
#include "node.hpp"

#include <cstdint>
#include <optional>
#include <set>
#include <string>

class OptionDiagnosticVisitor : public CodeVisitor {
public:
  MesonMetadata *metadata;

  explicit OptionDiagnosticVisitor(MesonMetadata *metadata)
      : metadata(metadata) {}

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
  std::set<std::string> options;
  void checkName(const StringLiteral *sl);
  void validateStringOption(const Node *defaultValue) const;
  void validateIntegerOption(const ArgumentList *al, const Node *defaultValue);
  void validateBooleanOption(const Node *defaultValue) const;
  void validateFeatureOption(const Node *defaultValue) const;
  void validateArrayOption(const Node *defaultValue,
                           const ArgumentList *al) const;
  void validateComboOption(const Node *defaultValue,
                           const ArgumentList *al) const;
  void
  extractArrayChoices(const ArgumentList *al,
                      std::shared_ptr<std::set<std::string>> *choices) const;
  std::optional<int64_t> parseInt(const Node *node);
  std::optional<int64_t> parseString(const Node *node) const;
  std::optional<int64_t> fetchIntOrNullOpt(const ArgumentList *al,
                                           const std::string &kwarg);
};
