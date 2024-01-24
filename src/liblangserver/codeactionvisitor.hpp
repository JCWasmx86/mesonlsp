#pragma once

#include "function.hpp"
#include "lsptypes.hpp"
#include "mesontree.hpp"
#include "node.hpp"

#include <cstddef>
#include <memory>
#include <optional>
#include <string>
#include <utility>
#include <vector>

class CodeActionVisitor : public CodeVisitor {
public:
  std::vector<CodeAction> actions;
  const LSPRange &editorRange;
  const std::string uri;
  const MesonTree *tree;

  CodeActionVisitor(const LSPRange &range, std::string uri,
                    const MesonTree *tree)
      : editorRange(range), uri(std::move(uri)), tree(tree) {}

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
  bool inRange(const Node *node, bool add = true);
  void makeIntegerToBaseAction(const Node *node);
  void makeCopyFileAction(const Node *node);
  void makeDeclareDependencyAction(const Node *node);
  void makeLibraryToGenericAction(const Node *node);
  void makeSharedLibraryToModuleAction(const Node *node);
  void makeModuleToSharedLibraryAction(const Node *node);
  void makeSortFilenamesAction(const Node *node);
  void makeSortFilenamesIASAction(const Node *node);
  void makeSortFilenamesSAIAction(const Node *node);
  void makeActionForBase(const IntegerLiteral *il, const std::string &title,
                         const std::string &prefix, const std::string &val);
  bool expectedArgsForCopyFile(const ArgumentList *al);
  std::optional<std::vector<const StringLiteral *>>
  extractStringLiterals(const ArgumentList *al, size_t omitCount);
  std::vector<const Node *> extractNodes(const ArgumentList *al,
                                         size_t omitCount);
  std::optional<std::vector<const Node *>>
  extractSortableNodes(const ArgumentList *al, size_t omitCount);

  static bool createsLibrary(const std::shared_ptr<Function> &func) {
    auto name = func->id();
    return name == "static_library" || name == "shared_library" ||
           name == "library";
  }

  static std::optional<size_t>
  isSortableFunction(const std::shared_ptr<Function> &func) {
    auto name = func->id();
    if (name == "both_libraries" || name == "build_target" ||
        name == "executable" || name == "jar" || name == "library" ||
        name == "shared_library" || name == "shared_module" ||
        name == "static_library") {
      return 1;
    }
    if (name == "files" || name == "include_directories" ||
        name == "install_data") {
      return 0;
    }
    return std::nullopt;
  }

  static std::optional<std::string>
  extractVariablename(const FunctionExpression *fExpr) {
    const auto *parent = fExpr->parent;
    if (!parent) {
      return std::nullopt;
    }
    const auto *ass = dynamic_cast<const AssignmentStatement *>(parent);
    if (!ass) {
      return std::nullopt;
    }
    const auto *idExpr = dynamic_cast<const IdExpression *>(ass->lhs.get());
    if (!idExpr) {
      return std::nullopt;
    }
    return idExpr->id;
  }

  static bool sortStrLiterals(const Node *lhs, const Node *rhs) {
    const auto *lhsSL = dynamic_cast<const StringLiteral *>(lhs);
    const auto *rhsSL = dynamic_cast<const StringLiteral *>(rhs);
    assert(lhsSL);
    assert(rhsSL);
    auto aC = std::ranges::count(lhsSL->id, '/');
    auto bC = std::ranges::count(rhsSL->id, '/');
    if (aC != bC) {
      return aC < bC; // Sort based on the count of slashes
    }
    return lhsSL->id < rhsSL->id; // If counts are equal, sort lexicographically
  }
};
