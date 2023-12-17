#pragma once

#include "function.hpp"
#include "location.hpp"
#include "sourcefile.hpp"

#include <cstdint>
#include <memory>
#include <optional>
#include <string>
#include <tree_sitter/api.h>
#include <type.hpp>
#include <vector>

class CodeVisitor;

class Node {
public:
  const std::shared_ptr<SourceFile> file;
  std::vector<std::shared_ptr<Type>> types;
  const Location *location;
  const Node *parent;

  virtual ~Node() {
    delete this->location;
    this->location = nullptr;
  }

  virtual void visitChildren(CodeVisitor *visitor) = 0;
  virtual void visit(CodeVisitor *visitor) = 0;
  virtual void setParents() = 0;

protected:
  Node(std::shared_ptr<SourceFile> file, TSNode node);
};

class KeywordItem : public Node {
public:
  std::shared_ptr<Node> key;
  std::shared_ptr<Node> value;
  std::optional<std::string> name;
  KeywordItem(std::shared_ptr<SourceFile> file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class ArgumentList : public Node {
public:
  std::vector<std::shared_ptr<Node>> args;
  ArgumentList(std::shared_ptr<SourceFile> file, TSNode node);

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;

  std::optional<std::shared_ptr<Node>> getPositionalArg(uint32_t idx) {
    if (idx > this->args.size()) {
      return std::nullopt;
    }
    return this->args[0];
  }

  std::optional<std::shared_ptr<Node>> getKwarg(const std::string &name) {
    for (const auto &arg : this->args) {
      auto *keywordItem = dynamic_cast<KeywordItem *>(arg.get());
      if (keywordItem == nullptr) {
        continue;
      }
      auto kwname = keywordItem->name;
      if (kwname.has_value() && kwname == name) {
        return keywordItem->value;
      }
    }
    return std::nullopt;
  }
};

class ArrayLiteral : public Node {
public:
  std::vector<std::shared_ptr<Node>> args;
  ArrayLiteral(std::shared_ptr<SourceFile> file, TSNode node);
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

class AssignmentStatement : public Node {
public:
  std::shared_ptr<Node> lhs;
  std::shared_ptr<Node> rhs;
  AssignmentOperator op;
  AssignmentStatement(std::shared_ptr<SourceFile> file, TSNode node);
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

class BinaryExpression : public Node {
public:
  std::shared_ptr<Node> lhs;
  std::shared_ptr<Node> rhs;
  BinaryOperator op;

  BinaryExpression(std::shared_ptr<SourceFile> file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class BooleanLiteral : public Node {
public:
  bool value;
  BooleanLiteral(std::shared_ptr<SourceFile> file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class BreakNode : public Node {
public:
  BreakNode(std::shared_ptr<SourceFile> file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class BuildDefinition : public Node {
public:
  std::vector<std::shared_ptr<Node>> stmts;
  BuildDefinition(std::shared_ptr<SourceFile> file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class ConditionalExpression : public Node {
public:
  std::shared_ptr<Node> condition;
  std::shared_ptr<Node> ifTrue;
  std::shared_ptr<Node> ifFalse;
  ConditionalExpression(std::shared_ptr<SourceFile> file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class ContinueNode : public Node {
public:
  ContinueNode(std::shared_ptr<SourceFile> file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class DictionaryLiteral : public Node {
public:
  std::vector<std::shared_ptr<Node>> values;
  DictionaryLiteral(std::shared_ptr<SourceFile> file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class ErrorNode : public Node {
public:
  std::string message;

  ErrorNode(std::shared_ptr<SourceFile> file, TSNode node, std::string message)
      : Node(file, node), message(message) {}

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class IdExpression : public Node {
public:
  std::string id;
  IdExpression(std::shared_ptr<SourceFile> file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

#define INVALID_FUNCTION_NAME "<<<Error>>>"

class FunctionExpression : public Node {
public:
  std::shared_ptr<Node> id;
  std::shared_ptr<Node> args;
  std::shared_ptr<Function> function;
  FunctionExpression(std::shared_ptr<SourceFile> file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;

  std::string functionName() {
    auto *idExpr = dynamic_cast<IdExpression *>(this->id.get());
    if (idExpr == nullptr) {
      return INVALID_FUNCTION_NAME;
    }
    return idExpr->id;
  }
};

class IntegerLiteral : public Node {
public:
  uint64_t value_as_int;
  std::string value;
  IntegerLiteral(std::shared_ptr<SourceFile> file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class IterationStatement : public Node {
public:
  std::vector<std::shared_ptr<Node>> ids;
  std::shared_ptr<Node> expression;
  std::vector<std::shared_ptr<Node>> stmts;
  IterationStatement(std::shared_ptr<SourceFile> file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class KeyValueItem : public Node {
public:
  std::shared_ptr<Node> key;
  std::shared_ptr<Node> value;
  KeyValueItem(std::shared_ptr<SourceFile> file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class MethodExpression : public Node {
public:
  std::shared_ptr<Node> obj;
  std::shared_ptr<Node> id;
  std::shared_ptr<Node> args;
  MethodExpression(std::shared_ptr<SourceFile> file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class SelectionStatement : public Node {
public:
  std::vector<std::shared_ptr<Node>> conditions;
  std::vector<std::vector<std::shared_ptr<Node>>> blocks;
  SelectionStatement(std::shared_ptr<SourceFile> file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class StringLiteral : public Node {
public:
  std::string id;
  bool isFormat;
  StringLiteral(std::shared_ptr<SourceFile> file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

class SubscriptExpression : public Node {
public:
  std::shared_ptr<Node> outer;
  std::shared_ptr<Node> inner;
  SubscriptExpression(std::shared_ptr<SourceFile> file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

enum UnaryOperator { Not, ExclamationMark, UnaryMinus, UnaryOther };

class UnaryExpression : public Node {
public:
  std::shared_ptr<Node> expression;
  UnaryOperator op;
  UnaryExpression(std::shared_ptr<SourceFile> file, TSNode node);
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
};

std::shared_ptr<Node> makeNode(std::shared_ptr<SourceFile> file, TSNode node);

class CodeVisitor {
public:
  CodeVisitor() {}

  virtual ~CodeVisitor() {}

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