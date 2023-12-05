#pragma once

#include "location.hpp"
#include "sourcefile.hpp"
#include <cstdint>
#include <memory>
#include <string>
#include <tree_sitter/api.h>
#include <type.hpp>
#include <vector>

class Node {
public:
  const std::shared_ptr<MesonSourceFile> file;
  std::vector<std::shared_ptr<Type>> types;
  const Location *location;
  const std::weak_ptr<Node> parent;

  ~Node() {
    delete this->location;
    this->location = nullptr;
  }

protected:
  Node(std::shared_ptr<MesonSourceFile> file, TSNode node);
};

class ArgumentList : public Node {
public:
  std::vector<std::shared_ptr<Node>> args;
  ArgumentList(std::shared_ptr<MesonSourceFile> file, TSNode node);
};

class ArrayLiteral : public Node {
public:
  std::vector<std::shared_ptr<Node>> args;
  ArrayLiteral(std::shared_ptr<MesonSourceFile> file, TSNode node);
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
  AssignmentStatement(std::shared_ptr<MesonSourceFile> file, TSNode node);
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

  BinaryExpression(std::shared_ptr<MesonSourceFile> file, TSNode node);
};

class BooleanLiteral : public Node {
public:
  bool value;
  BooleanLiteral(std::shared_ptr<MesonSourceFile> file, TSNode node);
};

class BreakNode : public Node {
public:
  BreakNode(std::shared_ptr<MesonSourceFile> file, TSNode node);
};

class BuildDefinition : public Node {
public:
  std::vector<std::shared_ptr<Node>> stmts;
  BuildDefinition(std::shared_ptr<MesonSourceFile> file, TSNode node);
};

class ConditionalExpression : public Node {
public:
  std::shared_ptr<Node> condition;
  std::shared_ptr<Node> ifTrue;
  std::shared_ptr<Node> ifFalse;
  ConditionalExpression(std::shared_ptr<MesonSourceFile> file, TSNode node);
};

class ContinueNode : public Node {
public:
  ContinueNode(std::shared_ptr<MesonSourceFile> file, TSNode node);
};

class DictionaryLiteral : public Node {
public:
  std::vector<std::shared_ptr<Node>> values;
  DictionaryLiteral(std::shared_ptr<MesonSourceFile> file, TSNode node);
};

class ErrorNode : public Node {
public:
  std::string message;
  ErrorNode(std::shared_ptr<MesonSourceFile> file, TSNode node,
            std::string message)
      : Node(file, node), message(message) {}
};

class FunctionExpression : public Node {
public:
  std::shared_ptr<Node> id;
  std::shared_ptr<Node> args;
  FunctionExpression(std::shared_ptr<MesonSourceFile> file, TSNode node);
};

class IdExpression : public Node {
public:
  std::string id;
  IdExpression(std::shared_ptr<MesonSourceFile> file, TSNode node);
};

class IntegerLiteral : public Node {
public:
  uint64_t value_as_int;
  std::string value;
  IntegerLiteral(std::shared_ptr<MesonSourceFile> file, TSNode node);
};

class IterationStatement : public Node {
public:
  std::vector<std::shared_ptr<Node>> ids;
  std::shared_ptr<Node> expression;
  std::vector<std::shared_ptr<Node>> stmts;
  IterationStatement(std::shared_ptr<MesonSourceFile> file, TSNode node);
};

class KeyValueItem : public Node {
public:
  std::shared_ptr<Node> key;
  std::shared_ptr<Node> value;
  KeyValueItem(std::shared_ptr<MesonSourceFile> file, TSNode node);
};

class KeywordItem : public Node {
public:
  std::shared_ptr<Node> key;
  std::shared_ptr<Node> value;
  KeywordItem(std::shared_ptr<MesonSourceFile> file, TSNode node);
};

class MethodExpression : public Node {
public:
  std::shared_ptr<Node> obj;
  std::shared_ptr<Node> id;
  std::shared_ptr<Node> args;
  MethodExpression(std::shared_ptr<MesonSourceFile> file, TSNode node);
};

class SelectionStatement : public Node {
public:
  std::vector<std::shared_ptr<Node>> conditions;
  std::vector<std::vector<std::shared_ptr<Node>>> blocks;
  SelectionStatement(std::shared_ptr<MesonSourceFile> file, TSNode node);
};

class StringLiteral : public Node {
public:
  std::string id;
  bool isFormat;
  StringLiteral(std::shared_ptr<MesonSourceFile> file, TSNode node);
};

class SubscriptExpression : public Node {
public:
  std::shared_ptr<Node> outer;
  std::shared_ptr<Node> inner;
  SubscriptExpression(std::shared_ptr<MesonSourceFile> file, TSNode node);
};

enum UnaryOperator { Not, ExclamationMark, UnaryMinus, UnaryOther };
class UnaryExpression : public Node {
public:
  std::shared_ptr<Node> expression;
  UnaryOperator op;
  UnaryExpression(std::shared_ptr<MesonSourceFile> file, TSNode node);
};

std::shared_ptr<Node> make_node(std::shared_ptr<MesonSourceFile> file,
                                TSNode node);