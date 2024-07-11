#pragma once

#include "function.hpp"
#include "location.hpp"
#include "sourcefile.hpp"

#include <cassert>
#include <cstdint>
#include <memory>
#include <optional>
#include <string>
#include <tree_sitter/api.h>
#include <type.hpp>
#include <utility>
#include <vector>

class CodeVisitor;

extern const std::string INVALID_FUNCTION_NAME_STR; // NOLINT
extern const std::string INVALID_KEY_NAME_STR;      // NOLINT

enum class NodeType {
  ARGUMENT_LIST,
  ARRAY_LITERAL,
  ASSIGNMENT_STATEMENT,
  BINARY_EXPRESSION,
  BOOLEAN_LITERAL,
  BUILD_DEFINITION,
  CONDITIONAL_EXPRESSION,
  DICTIONARY_LITERAL,
  FUNCTION_EXPRESSION,
  ID_EXPRESSION,
  INTEGER_LITERAL,
  ITERATION_STATEMENT,
  KEY_VALUE_ITEM,
  KEYWORD_ITEM,
  METHOD_EXPRESSION,
  SELECTION_STATEMENT,
  STRING_LITERAL,
  SUBSCRIPT_EXPRESSION,
  UNARY_EXPRESSION,
  ERROR_NODE,
  BREAK_NODE,
  CONTINUE_NODE,
};

class Node {
public:
  const std::shared_ptr<SourceFile> file;
  std::vector<std::shared_ptr<Type>> types;
  Location location;
  Node *parent;
  const NodeType type;

  virtual ~Node() = default;

  virtual void visitChildren(CodeVisitor *visitor) = 0;
  virtual void visit(CodeVisitor *visitor) = 0;
  virtual void setParents() = 0;
  virtual std::string toString() = 0;

  bool equals(const Node *other) const {
    const auto &otherLoc = other->location;
    if (this->location.columns != otherLoc.columns ||
        this->location.lines != otherLoc.lines) {
      return false;
    }
    return this->file->hashed == other->file->hashed;
  }

  explicit Node(NodeType type) : type(type) {}

  Node(Node const &) = delete;
  Node &operator=(Node const &) = delete;
  Node(Node &&) = delete;

protected:
  Node(NodeType type, std::shared_ptr<SourceFile> file, const TSNode &node);

  Node(NodeType type, std::shared_ptr<SourceFile> file,
       const std::pair<uint32_t, uint32_t> &start,
       const std::pair<uint32_t, uint32_t> &end)
      : file(std::move(file)), location(start, end), type(type) {}

  Node(NodeType type, std::shared_ptr<SourceFile> file,
       const std::shared_ptr<Node> &start, const std::shared_ptr<Node> &end)
      : file(std::move(file)), location(start->location, end->location),
        type(type) {}

  Node(NodeType type, std::shared_ptr<SourceFile> file,
       const std::pair<uint32_t, uint32_t> &start,
       const std::shared_ptr<Node> &end)
      : file(std::move(file)), location(start, end->location), type(type) {}

  Node(NodeType type, std::shared_ptr<SourceFile> file,
       const std::shared_ptr<Node> &start,
       const std::pair<uint32_t, uint32_t> &end)
      : file(std::move(file)),
        location(start->location.startLine, end.first,
                 start->location.startColumn, end.second),
        type(type) {}
};

class ArrayLiteral final : public Node {
public:
  std::vector<std::shared_ptr<Node>> args;
  ArrayLiteral(const std::shared_ptr<SourceFile> &file, const TSNode &node);

  ArrayLiteral(std::shared_ptr<SourceFile> file,
               std::vector<std::shared_ptr<Node>> args,
               const std::pair<uint32_t, uint32_t> &start,
               const std::pair<uint32_t, uint32_t> &end)
      : Node(NodeType::ARRAY_LITERAL, std::move(file), start, end),
        args(std::move(args)) {}

  explicit ArrayLiteral(std::vector<std::shared_ptr<Node>> args)
      : Node(NodeType::ARRAY_LITERAL) {
    this->args = std::move(args);
  }

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
  std::string toString() override;
};

enum class AssignmentOperator {
  EQUALS,
  MUL_EQUALS,
  DIV_EQUALS,
  MOD_EQUALS,
  PLUS_EQUALS,
  MINUS_EQUALS,
  ASSIGNMENT_OP_OTHER,
};

inline std::string enum2String(AssignmentOperator op) {
  using enum AssignmentOperator;
  switch (op) {
  case EQUALS:
    return "=";
  case MUL_EQUALS:
    return "*=";
  case DIV_EQUALS:
    return "/=";
  case MOD_EQUALS:
    return "%=";
  case PLUS_EQUALS:
    return "+=";
  case MINUS_EQUALS:
    return "-=";
  case ASSIGNMENT_OP_OTHER:
    return "<<Unknown>>";
  }
  std::unreachable();
}

class AssignmentStatement final : public Node {
public:
  std::shared_ptr<Node> lhs;
  std::shared_ptr<Node> rhs;
  AssignmentOperator op;
  AssignmentStatement(const std::shared_ptr<SourceFile> &file,
                      const TSNode &node);

  AssignmentStatement(std::shared_ptr<SourceFile> file,
                      const std::shared_ptr<Node> &lhs,
                      const std::shared_ptr<Node> &rhs, AssignmentOperator op)
      : Node(NodeType::ASSIGNMENT_STATEMENT, std::move(file), lhs, rhs),
        lhs(lhs), rhs(rhs), op(op) {}

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
  std::string toString() override;
};

enum class BinaryOperator {
  PLUS,
  MINUS,
  MUL,
  DIV,
  MODULO,
  EQUALS_EQUALS,
  NOT_EQUALS,
  GT,
  LT,
  GE,
  LE,
  IN,
  NOT_IN,
  OR,
  AND,
  BIN_OP_OTHER,
};

inline std::string enum2String(BinaryOperator op) {
  using enum BinaryOperator;
  switch (op) {
  case PLUS:
    return "+";
  case MINUS:
    return "-";
  case MUL:
    return "*";
  case DIV:
    return "/";
  case MODULO:
    return "%";
  case EQUALS_EQUALS:
    return "==";
  case NOT_EQUALS:
    return "!=";
  case GT:
    return ">";
  case LT:
    return "<";
  case GE:
    return ">=";
  case LE:
    return "<=";
  case IN:
    return "in";
  case NOT_IN:
    return "not in";
  case OR:
    return "or";
  case AND:
    return "and";
  case BIN_OP_OTHER:
    return "<<Unknown>>";
  }
  std::unreachable();
}

class BinaryExpression final : public Node {
public:
  std::shared_ptr<Node> lhs;
  std::shared_ptr<Node> rhs;
  BinaryOperator op;

  BinaryExpression(const std::shared_ptr<SourceFile> &file, const TSNode &node);

  BinaryExpression(std::shared_ptr<SourceFile> file,
                   const std::shared_ptr<Node> &lhs,
                   const std::shared_ptr<Node> &rhs, BinaryOperator op)
      : Node(NodeType::BINARY_EXPRESSION, std::move(file), lhs, rhs), lhs(lhs),
        rhs(rhs), op(op) {}

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
  std::string toString() override;
};

class BooleanLiteral final : public Node {
public:
  bool value;
  BooleanLiteral(const std::shared_ptr<SourceFile> &file, const TSNode &node);

  BooleanLiteral(std::shared_ptr<SourceFile> file,
                 const std::pair<uint32_t, uint32_t> &start,
                 const std::pair<uint32_t, uint32_t> &end, bool value)
      : Node(NodeType::BOOLEAN_LITERAL, std::move(file), start, end),
        value(value) {}

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
  std::string toString() override;
};

class BreakNode final : public Node {
public:
  BreakNode(std::shared_ptr<SourceFile> file, const TSNode &node);

  BreakNode(std::shared_ptr<SourceFile> file,
            const std::pair<uint32_t, uint32_t> &start,
            const std::pair<uint32_t, uint32_t> &end)
      : Node(NodeType::BREAK_NODE, std::move(file), start, end) {}

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
  std::string toString() override;
};

class ParsingError {
public:
  Location range;
  std::string message;

  ParsingError(const Location &range, std::string message)
      : range(range), message(std::move(message)) {}
};

class BuildDefinition final : public Node {
public:
  std::vector<std::shared_ptr<Node>> stmts;
  std::vector<ParsingError> parsingErrors;
  uint32_t numStringLiterals = 0;
  uint32_t numIdentifiers = 0;
  uint32_t numArrayAccesses = 0;
  uint32_t numFunctionCalls = 0;
  uint32_t numKwargs = 0;

  BuildDefinition(const std::shared_ptr<SourceFile> &file, const TSNode &node);

  BuildDefinition(const std::shared_ptr<SourceFile> &file,
                  std::vector<std::shared_ptr<Node>> stmts,
                  const std::pair<uint32_t, uint32_t> &start,
                  const std::pair<uint32_t, uint32_t> &end,
                  std::vector<ParsingError> parsingErrors,
                  std::array<uint32_t, 5> &metadata)
      : Node(NodeType::BUILD_DEFINITION, file, start, end),
        stmts(std::move(stmts)), parsingErrors(std::move(parsingErrors)),
        numStringLiterals(metadata[0]), numIdentifiers(metadata[1]),
        numArrayAccesses(metadata[2]), numFunctionCalls(metadata[3]),
        numKwargs(metadata[4]) {}

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
  std::string toString() override;
};

class ConditionalExpression final : public Node {
public:
  std::shared_ptr<Node> condition;
  std::shared_ptr<Node> ifTrue;
  std::shared_ptr<Node> ifFalse;
  ConditionalExpression(const std::shared_ptr<SourceFile> &file,
                        const TSNode &node);

  ConditionalExpression(const std::shared_ptr<SourceFile> &file,
                        const std::shared_ptr<Node> &condition,
                        std::shared_ptr<Node> ifTrue,
                        const std::shared_ptr<Node> &ifFalse)
      : Node(NodeType::CONDITIONAL_EXPRESSION, file, condition, ifFalse),
        condition(condition), ifTrue(std::move(ifTrue)), ifFalse(ifFalse) {}

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
  std::string toString() override;
};

class ContinueNode final : public Node {
public:
  ContinueNode(std::shared_ptr<SourceFile> file, const TSNode &node);

  ContinueNode(std::shared_ptr<SourceFile> file,
               const std::pair<uint32_t, uint32_t> &start,
               const std::pair<uint32_t, uint32_t> &end)
      : Node(NodeType::CONTINUE_NODE, std::move(file), start, end) {}

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
  std::string toString() override;
};

class DictionaryLiteral final : public Node {
public:
  std::vector<std::shared_ptr<Node>> values;
  DictionaryLiteral(const std::shared_ptr<SourceFile> &file,
                    const TSNode &node);

  DictionaryLiteral(std::shared_ptr<SourceFile> file,
                    std::vector<std::shared_ptr<Node>> values,
                    const std::pair<uint32_t, uint32_t> &start,
                    const std::pair<uint32_t, uint32_t> &end)
      : Node(NodeType::DICTIONARY_LITERAL, std::move(file), start, end),
        values(std::move(values)) {}

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
  std::string toString() override;
};

class ErrorNode final : public Node {
public:
  std::string message;

  ErrorNode(std::shared_ptr<SourceFile> file, const TSNode &node,
            std::string message)
      : Node(NodeType::ERROR_NODE, std::move(file), node),
        message(std::move(message)) {}

  ErrorNode(const std::shared_ptr<SourceFile> &file,
            const std::pair<uint32_t, uint32_t> &start,
            const std::pair<uint32_t, uint32_t> &end, std::string message)
      : Node(NodeType::ERROR_NODE, file, start, end),
        message(std::move(message)) {}

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
  std::string toString() override;
};

class IdExpression final : public Node {
public:
  std::string id;
  uint32_t hash;
  IdExpression(const std::shared_ptr<SourceFile> &file, const TSNode &node);

  IdExpression(const std::shared_ptr<SourceFile> &file, std::string str,
               uint32_t hash, const std::pair<uint32_t, uint32_t> &start,
               const std::pair<uint32_t, uint32_t> &end)
      : Node(NodeType::ID_EXPRESSION, file, start, end), id(std::move(str)),
        hash(hash) {}

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
  std::string toString() override;
};

constexpr const char *INVALID_FUNCTION_NAME = "<<<Error>>>";
constexpr const char *INVALID_KEY_NAME = "<<<$$$$ERROR$$$$>>>";

class FunctionExpression final : public Node {
public:
  std::shared_ptr<Node> id;
  std::shared_ptr<Node> args;
  std::shared_ptr<Function> function;
  FunctionExpression(const std::shared_ptr<SourceFile> &file,
                     const TSNode &node);

  FunctionExpression(const std::shared_ptr<SourceFile> &file,
                     const std::shared_ptr<Node> &name,
                     const std::shared_ptr<Node> &args,
                     const std::pair<uint32_t, uint32_t> &end)
      : Node(NodeType::FUNCTION_EXPRESSION, file, name, end), id(name),
        args(args) {}

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
  std::string toString() override;

  [[nodiscard]] const std::string &functionName() const {
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
  IntegerLiteral(const std::shared_ptr<SourceFile> &file, const TSNode &node);

  IntegerLiteral(const std::shared_ptr<SourceFile> &file, uint64_t valueAsInt,
                 std::string str, const std::pair<uint32_t, uint32_t> &start,
                 const std::pair<uint32_t, uint32_t> &end)
      : Node(NodeType::INTEGER_LITERAL, file, start, end),
        valueAsInt(valueAsInt), value(std::move(str)) {}

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
  std::string toString() override;
};

class IterationStatement final : public Node {
public:
  std::vector<std::shared_ptr<Node>> ids;
  std::shared_ptr<Node> expression;
  std::vector<std::shared_ptr<Node>> stmts;
  IterationStatement(const std::shared_ptr<SourceFile> &file,
                     const TSNode &node);

  IterationStatement(const std::shared_ptr<SourceFile> &file,
                     std::vector<std::shared_ptr<Node>> ids,
                     std::shared_ptr<Node> expression,
                     std::vector<std::shared_ptr<Node>> stmts,
                     const std::pair<uint32_t, uint32_t> &start,
                     const std::pair<uint32_t, uint32_t> &end)
      : Node(NodeType::ITERATION_STATEMENT, file, start, end),
        ids(std::move(ids)), expression(std::move(expression)),
        stmts(std::move(stmts)) {}

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
  std::string toString() override;
};

class StringLiteral final : public Node {
public:
  std::string id;
  bool isFormat = false;
  bool hasEnoughAts = false;
  StringLiteral(const std::shared_ptr<SourceFile> &file, const TSNode &node);

  StringLiteral(const std::shared_ptr<SourceFile> &file, std::string str,
                const std::pair<uint32_t, uint32_t> &start,
                const std::pair<uint32_t, uint32_t> &end, bool format,
                bool hasEnoughAts)
      : Node(NodeType::STRING_LITERAL, file, start, end), id(std::move(str)),
        isFormat(format), hasEnoughAts(hasEnoughAts) {}

  explicit StringLiteral(std::string str) : Node(NodeType::STRING_LITERAL) {
    this->id = std::move(str);
  }

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
  std::string toString() override;
};

class KeyValueItem final : public Node {
public:
  std::shared_ptr<Node> key;
  std::shared_ptr<Node> value;
  KeyValueItem(const std::shared_ptr<SourceFile> &file, const TSNode &node);

  KeyValueItem(const std::shared_ptr<SourceFile> &file,
               const std::shared_ptr<Node> &key,
               const std::shared_ptr<Node> &value)
      : Node(NodeType::KEY_VALUE_ITEM, file, key, value), key(key),
        value(value) {}

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
  std::string toString() override;

  [[nodiscard]] const std::string &getKeyName() const {
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
  MethodExpression(const std::shared_ptr<SourceFile> &file, const TSNode &node);
  MethodExpression(const std::shared_ptr<SourceFile> &file,
                   const std::shared_ptr<Node> &object,
                   const std::shared_ptr<Node> &name,
                   const std::shared_ptr<Node> &args,
                   const std::pair<uint32_t, uint32_t> &pair)
      : Node(NodeType::METHOD_EXPRESSION, file, object, pair), obj(object),
        id(name), args(args) {};
  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
  std::string toString() override;
};

class SelectionStatement final : public Node {
public:
  std::vector<std::shared_ptr<Node>> conditions;
  std::vector<std::vector<std::shared_ptr<Node>>> blocks;
  SelectionStatement(const std::shared_ptr<SourceFile> &file,
                     const TSNode &node);

  SelectionStatement(const std::shared_ptr<SourceFile> &file,
                     std::vector<std::shared_ptr<Node>> conditions,
                     std::vector<std::vector<std::shared_ptr<Node>>> blocks,
                     const std::pair<uint32_t, uint32_t> &start,
                     const std::pair<uint32_t, uint32_t> &end)
      : Node(NodeType::SELECTION_STATEMENT, file, start, end),
        conditions(std::move(conditions)), blocks(std::move(blocks)) {}

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
  std::string toString() override;
};

class SubscriptExpression final : public Node {
public:
  std::shared_ptr<Node> outer;
  std::shared_ptr<Node> inner;
  SubscriptExpression(const std::shared_ptr<SourceFile> &file,
                      const TSNode &node);

  SubscriptExpression(const std::shared_ptr<SourceFile> &file,
                      const std::shared_ptr<Node> &outer,
                      const std::shared_ptr<Node> &inner,
                      const std::pair<uint32_t, uint32_t> &end)
      : Node(NodeType::SUBSCRIPT_EXPRESSION, file, outer, end), outer(outer),
        inner(inner) {}

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
  std::string toString() override;
};

enum class UnaryOperator { NOT, EXCLAMATION_MARK, UNARY_MINUS, UNARY_OTHER };

inline std::string enum2String(UnaryOperator op) {
  using enum UnaryOperator;
  switch (op) {
  case UnaryOperator::NOT:
    return "not";
  case UnaryOperator::EXCLAMATION_MARK:
    return "!";
  case UnaryOperator::UNARY_MINUS:
    return "-";
  case UnaryOperator::UNARY_OTHER:
    return "<<Unknown>>";
  }
  std::unreachable();
}

class UnaryExpression final : public Node {
public:
  std::shared_ptr<Node> expression;
  UnaryOperator op;
  UnaryExpression(const std::shared_ptr<SourceFile> &file, const TSNode &node);

  UnaryExpression(const std::shared_ptr<SourceFile> &file,
                  const std::pair<uint32_t, uint32_t> &start, UnaryOperator op,
                  const std::shared_ptr<Node> &rhs)
      : Node(NodeType::UNARY_EXPRESSION, file, start, rhs), expression(rhs),
        op(op) {}

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
  std::string toString() override;
};

class KeywordItem final : public Node {
public:
  std::shared_ptr<Node> key;
  std::shared_ptr<Node> value;
  std::optional<std::string> name;
  KeywordItem(const std::shared_ptr<SourceFile> &file, const TSNode &node);

  KeywordItem(const std::shared_ptr<SourceFile> &file,
              const std::shared_ptr<Node> &key,
              const std::shared_ptr<Node> &value)
      : Node(NodeType::KEYWORD_ITEM, file, key, value), key(key), value(value) {
    auto *casted = dynamic_cast<IdExpression *>(this->key.get());
    if (casted == nullptr) {
      this->name = std::nullopt;
      return;
    }
    this->name = casted->id;
  }

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
  std::string toString() override;
};

class ArgumentList final : public Node {
public:
  std::vector<std::shared_ptr<Node>> args;
  ArgumentList(const std::shared_ptr<SourceFile> &file, const TSNode &node);

  ArgumentList(std::shared_ptr<SourceFile> file,
               std::vector<std::shared_ptr<Node>> args,
               const std::pair<uint32_t, uint32_t> &start,
               const std::pair<uint32_t, uint32_t> &end)
      : Node(NodeType::ARGUMENT_LIST, std::move(file), start, end),
        args(std::move(args)) {}

  void visitChildren(CodeVisitor *visitor) override;
  void visit(CodeVisitor *visitor) override;
  void setParents() override;
  std::string toString() override;

  [[nodiscard]] std::optional<std::shared_ptr<Node>>
  getPositionalArg(uint32_t idx) const {
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

  [[nodiscard]] std::optional<std::shared_ptr<Node>>
  getKwarg(const std::string &name) const {
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

std::shared_ptr<Node> makeNode(const std::shared_ptr<SourceFile> &file,
                               const TSNode &node);

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
