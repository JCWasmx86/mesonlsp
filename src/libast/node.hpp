#pragma once

#include "location.hpp"
#include "sourcefile.hpp"
#include <cstdint>
#include <memory>
#include <string>
#include <type.hpp>
#include <vector>

class Node
{
public:
  const MesonSourceFile file;
  std::vector<std::shared_ptr<Type>> types;
  const Location location;
  const std::weak_ptr<Node> parent;
};

class ArgumentList : public Node
{
public:
  std::vector<std::shared_ptr<Node>> args;
};

class ArrayLiteral : public Node
{
public:
  std::vector<std::shared_ptr<Node>> args;
};

enum AssignmentOperator
{
  Equals,
  MulEquals,
  DivEquals,
  ModEquals,
  PlusEquals,
  MinusEquals,
  Other,
};

class AssignmentStatement : public Node
{
public:
  std::shared_ptr<Node> lhs;
  std::shared_ptr<Node> rhs;
  AssignmentOperator op;
};

enum BinaryOperator
{
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
};

class BinaryExpression : public Node
{
public:
  std::shared_ptr<Node> lhs;
  std::shared_ptr<Node> rhs;
  BinaryOperator op;
};

class BooleanLiteral : public Node
{
public:
  bool value;
};

class BreakNode : public Node
{};

class BuildDefinition : public Node
{
public:
  std::vector<std::shared_ptr<Node>> stmts;
};

class ContinueNode : public Node
{};

class DictionaryLiteral : public Node
{
public:
  std::vector<std::shared_ptr<Node>> values;
};

class ErrorNode : public Node
{
public:
  std::string message;
};

class FunctionExpression : public Node
{
public:
  std::shared_ptr<Node> id;
  std::shared_ptr<Node> args;
};

class IdExpression : public Node
{
public:
  std::string id;
};

class IntegerLiteral : public Node
{
public:
  uint64_t value_as_int;
  std::string value;
};

class IterationStatement : public Node
{
public:
  std::vector<std::shared_ptr<Node>> ids;
  std::shared_ptr<Node> expression;
  std::vector<std::shared_ptr<Node>> stmts;
};

class KeyValueItem : public Node
{
public:
  std::shared_ptr<Node> key;
  std::shared_ptr<Node> value;
};

class KeywordItem : public Node
{
public:
  std::shared_ptr<Node> key;
  std::shared_ptr<Node> value;
};

class MethodExpression : public Node
{
public:
  std::shared_ptr<Node> obj;
  std::shared_ptr<Node> id;
  std::shared_ptr<Node> args;
};

class SelectionStatement : public Node
{
public:
  std::vector<std::shared_ptr<Node>> conditions;
  std::vector<std::vector<std::shared_ptr<Node>>> blocks;
};

class StringLiteral : public Node
{
public:
  std::string id;
  bool isFormat;
};

class SubscriptExpression : public Node
{
public:
  std::shared_ptr<Node> outer;
  std::shared_ptr<Node> inner;
};

enum UnaryOperator
{
  Not,
  ExclamationMark,
  UnaryMinus,
};
class UnaryExpression : public Node
{
public:
  std::shared_ptr<Node> expression;
  UnaryOperator op;
};