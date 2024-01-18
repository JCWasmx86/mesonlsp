#pragma once

#include "function.hpp"
#include "location.hpp"
#include "sourcefile.hpp"

#include <cassert>
#include <cstdint>
#include <memory>
#include <optional>
#include <set>
#include <string>
#include <tree_sitter/api.h>
#include <type.hpp>
#include <utility>
#include <vector>

class CodeVisitor;

extern const std::string INVALID_FUNCTION_NAME_STR; // NOLINT
extern const std::string INVALID_KEY_NAME_STR;      // NOLINT

class Node {
public:
  const std::shared_ptr<SourceFile> file;
  std::vector<std::shared_ptr<Type>> types;
  const Location location;
  Node *parent;

  virtual ~Node() = default;

  virtual void visitChildren(CodeVisitor *visitor) = 0;
  virtual void visit(CodeVisitor *visitor) = 0;
  virtual void setParents() = 0;

  bool equals(const Node *other) const {
    if (this->file->file != other->file->file) {
      return false;
    }
    const auto *otherLoc = &other->location;
    return this->location.columns == otherLoc->columns &&
           this->location.lines == otherLoc->lines;
  }

  Node() = default;

  Node(Node const &) = delete;
  Node &operator=(Node const &) = delete;
  Node(Node &&) = delete;

protected:
  Node(std::shared_ptr<SourceFile> file, TSNode node);
};

class KeywordItem final : public Node {
public:
  std::shared_ptr<Node> key;
  std::shared_ptr<Node> value;
  std::optional<std::string> name;
  KeywordItem(const std::shared_ptr<SourceFile> &file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class ArgumentList final : public Node {
public:
  std::vector<std::shared_ptr<Node>> args;
  ArgumentList(const std::shared_ptr<SourceFile> &file, TSNode node);

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;

  std::optional<std::shared_ptr<Node>> getPositionalArg(uint32_t idx) const {
    if (idx >= this->args.size()) {
      return std::nullopt;
    }
    uint32_t posIdx = 0;
    for (const auto &arg : this->args) {
      const auto *keywordItem = dynamic_cast<KeywordItem *>(arg.get());
      if (keywordItem != nullptr) {
        continue;
      }
      if (idx == posIdx) {
        return this->args[idx];
      }
      posIdx++;
    }
    return std::nullopt;
  }

  std::optional<std::shared_ptr<Node>> getKwarg(const std::string &name) const {
    for (const auto &arg : this->args) {
      auto *keywordItem = dynamic_cast<KeywordItem *>(arg.get());
      if (keywordItem == nullptr) {
        continue;
      }
      const auto &kwname = keywordItem->name;
      if (kwname.has_value() && kwname == name) {
        return keywordItem->value;
      }
    }
    return std::nullopt;
  }
};

class ArrayLiteral final : public Node {
public:
  std::vector<std::shared_ptr<Node>> args;
  ArrayLiteral(const std::shared_ptr<SourceFile> &file, TSNode node);

  ArrayLiteral(std::vector<std::shared_ptr<Node>> args) {
    this->args = std::move(args);
  }

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

enum AssignmentOperator {
  Equals,
  MulEquals,
  DivEquals,
  ModEquals,
  PlusEquals,
  MinusEquals,
  AssignmentOpOther,
};

inline std::string enum2String(AssignmentOperator op) {
  switch (op) {
  case Equals:
    return "=";
  case MulEquals:
    return "*=";
  case DivEquals:
    return "/=";
  case ModEquals:
    return "%=";
  case PlusEquals:
    return "+=";
  case MinusEquals:
    return "-=";
  case AssignmentOpOther:
    return "<<Unknown>>";
  }
  assert(false);
}

class AssignmentStatement final : public Node {
public:
  std::shared_ptr<Node> lhs;
  std::shared_ptr<Node> rhs;
  AssignmentOperator op;
  AssignmentStatement(const std::shared_ptr<SourceFile> &file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

enum BinaryOperator {
  Plus,
  Minus,
  Mul,
  Div,
  Modulo,
  EqualsEquals,
  NotEquals,
  Gt,
  Lt,
  Ge,
  Le,
  In,
  NotIn,
  Or,
  And,
  BinOpOther,
};

inline std::string enum2String(BinaryOperator op) {
  switch (op) {
  case Plus:
    return "+";
  case Minus:
    return "-";
  case Mul:
    return "*";
  case Div:
    return "/";
  case Modulo:
    return "%";
  case EqualsEquals:
    return "==";
  case NotEquals:
    return "!=";
  case Gt:
    return ">";
  case Lt:
    return "<";
  case Ge:
    return ">=";
  case Le:
    return "<=";
  case In:
    return "in";
  case NotIn:
    return "not in";
  case Or:
    return "or";
  case And:
    return "and";
  case BinOpOther:
    return "<<Unknown>>";
  }
  assert(false);
}

class BinaryExpression final : public Node {
public:
  std::shared_ptr<Node> lhs;
  std::shared_ptr<Node> rhs;
  BinaryOperator op;

  BinaryExpression(const std::shared_ptr<SourceFile> &file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class BooleanLiteral final : public Node {
public:
  bool value;
  BooleanLiteral(const std::shared_ptr<SourceFile> &file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class BreakNode final : public Node {
public:
  BreakNode(std::shared_ptr<SourceFile> file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class BuildDefinition final : public Node {
public:
  std::vector<std::shared_ptr<Node>> stmts;
  BuildDefinition(const std::shared_ptr<SourceFile> &file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class ConditionalExpression final : public Node {
public:
  std::shared_ptr<Node> condition;
  std::shared_ptr<Node> ifTrue;
  std::shared_ptr<Node> ifFalse;
  ConditionalExpression(const std::shared_ptr<SourceFile> &file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class ContinueNode final : public Node {
public:
  ContinueNode(std::shared_ptr<SourceFile> file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class DictionaryLiteral final : public Node {
public:
  std::vector<std::shared_ptr<Node>> values;
  DictionaryLiteral(const std::shared_ptr<SourceFile> &file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class ErrorNode final : public Node {
public:
  std::string message;

  ErrorNode(std::shared_ptr<SourceFile> file, TSNode node, std::string message)
      : Node(std::move(file), node), message(std::move(message)) {}

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class IdExpression final : public Node {
public:
  std::string id;
  IdExpression(const std::shared_ptr<SourceFile> &file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

constexpr const char *INVALID_FUNCTION_NAME = "<<<Error>>>";
constexpr const char *INVALID_KEY_NAME = "<<<$$$$ERROR$$$$>>>";

class FunctionExpression final : public Node {
public:
  std::shared_ptr<Node> id;
  std::shared_ptr<Node> args;
  std::shared_ptr<Function> function;
  FunctionExpression(const std::shared_ptr<SourceFile> &file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;

  const std::string &functionName() const {
    const auto *idExpr = dynamic_cast<IdExpression *>(this->id.get());
    if (idExpr == nullptr) {
      return INVALID_FUNCTION_NAME_STR;
    }
    return idExpr->id;
  }
};

class IntegerLiteral final : public Node {
public:
  uint64_t valueAsInt;
  std::string value;
  IntegerLiteral(const std::shared_ptr<SourceFile> &file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class IterationStatement final : public Node {
public:
  std::vector<std::shared_ptr<Node>> ids;
  std::shared_ptr<Node> expression;
  std::vector<std::shared_ptr<Node>> stmts;
  IterationStatement(const std::shared_ptr<SourceFile> &file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class StringLiteral final : public Node {
public:
  std::string id;
  bool isFormat = false;
  StringLiteral(const std::shared_ptr<SourceFile> &file, TSNode node);

  explicit StringLiteral(std::string str) { this->id = std::move(str); }

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class KeyValueItem final : public Node {
public:
  std::shared_ptr<Node> key;
  std::shared_ptr<Node> value;
  KeyValueItem(const std::shared_ptr<SourceFile> &file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;

  const std::string &getKeyName() const {
    const auto *sl = dynamic_cast<StringLiteral *>(this->key.get());
    if (sl) {
      return sl->id;
    }
    return INVALID_KEY_NAME_STR;
  }
};

class MethodExpression final : public Node {
public:
  std::shared_ptr<Node> obj;
  std::shared_ptr<Node> id;
  std::shared_ptr<Node> args;
  std::shared_ptr<Method> method;
  MethodExpression(const std::shared_ptr<SourceFile> &file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class SelectionStatement final : public Node {
public:
  std::vector<std::shared_ptr<Node>> conditions;
  std::vector<std::vector<std::shared_ptr<Node>>> blocks;
  SelectionStatement(const std::shared_ptr<SourceFile> &file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class SubscriptExpression final : public Node {
public:
  std::shared_ptr<Node> outer;
  std::shared_ptr<Node> inner;
  SubscriptExpression(const std::shared_ptr<SourceFile> &file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

enum UnaryOperator { Not, ExclamationMark, UnaryMinus, UnaryOther };

class UnaryExpression final : public Node {
public:
  std::shared_ptr<Node> expression;
  UnaryOperator op;
  UnaryExpression(const std::shared_ptr<SourceFile> &file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

std::shared_ptr<Node> makeNode(const std::shared_ptr<SourceFile> &file,
                               TSNode node);

class CodeVisitor {
public:
  CodeVisitor() = default;

  virtual ~CodeVisitor() = default;

  virtual void visitArgumentList(ArgumentList *node) = 0;
  virtual void visitArrayLiteral(ArrayLiteral *node) = 0;
  virtual void visitAssignmentStatement(AssignmentStatement *node) = 0;
  virtual void visitBinaryExpression(BinaryExpression *node) = 0;
  virtual void visitBooleanLiteral(BooleanLiteral *node) = 0;
  virtual void visitBuildDefinition(BuildDefinition *node) = 0;
  virtual void visitConditionalExpression(ConditionalExpression *node) = 0;
  virtual void visitDictionaryLiteral(DictionaryLiteral *node) = 0;
  virtual void visitFunctionExpression(FunctionExpression *node) = 0;
  virtual void visitIdExpression(IdExpression *node) = 0;
  virtual void visitIntegerLiteral(IntegerLiteral *node) = 0;
  virtual void visitIterationStatement(IterationStatement *node) = 0;
  virtual void visitKeyValueItem(KeyValueItem *node) = 0;
  virtual void visitKeywordItem(KeywordItem *node) = 0;
  virtual void visitMethodExpression(MethodExpression *node) = 0;
  virtual void visitSelectionStatement(SelectionStatement *node) = 0;
  virtual void visitStringLiteral(StringLiteral *node) = 0;
  virtual void visitSubscriptExpression(SubscriptExpression *node) = 0;
  virtual void visitUnaryExpression(UnaryExpression *node) = 0;
  virtual void visitErrorNode(ErrorNode *node) = 0;
  virtual void visitBreakNode(BreakNode *node) = 0;
  virtual void visitContinueNode(ContinueNode *node) = 0;
};

std::vector<std::string> extractTextBetweenAtSymbols(const std::string &text);
std::set<uint64_t> extractIntegersBetweenAtSymbols(const std::string &text);
