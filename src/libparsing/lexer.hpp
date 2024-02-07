#pragma once
#include <cassert>
#include <cstdint>
#include <string>
#include <variant>
#include <vector>

enum class TokenType {
  TOKEOF,
  EOL,
  LPAREN,
  RPAREN,
  LBRACK,
  RBRACK,
  LCURL,
  RCURL,
  DOT,
  COMMA,
  COLON,
  QUESTION_MARK,
  PLUS,
  MINUS,
  STAR,
  SLASH,
  MODULO,
  ASSIGN,
  PLUS_ASSIGN,
  EQ,
  NEQ,
  GT,
  GEQ,
  LT,
  LEQ,
  IF,
  ELSE,
  ELIF,
  ENDIF,
  AND,
  OR,
  NOT,
  FOREACH,
  ENDFOREACH,
  IN,
  CONTINUE,
  BREAK,
  IDENTIFIER,
  STRING,
  NUMBER,
  TRUE,
  FALSE,
  INVALID,
};

inline std::string enum2String(TokenType type) {
  using enum TokenType;
  switch (type) {
  case TOKEOF:
    return "eof";
  case EOL:
    return "eol";
  case LPAREN:
    return "'('";
  case RPAREN:
    return "')'";
  case LBRACK:
    return "'['";
  case RBRACK:
    return "']'";
  case LCURL:
    return "'{'";
  case RCURL:
    return "'}'";
  case DOT:
    return "'.'";
  case COMMA:
    return "','";
  case COLON:
    return "':'";
  case QUESTION_MARK:
    return "'?'";
  case PLUS:
    return "'+'";
  case MINUS:
    return "'-'";
  case STAR:
    return "'*'";
  case SLASH:
    return "'/'";
  case MODULO:
    return "'%'";
  case ASSIGN:
    return "'='";
  case PLUS_ASSIGN:
    return "'+='";
  case EQ:
    return "'='";
  case NEQ:
    return "'!='";
  case GT:
    return "'>'";
  case GEQ:
    return "'>='";
  case LT:
    return "'<'";
  case LEQ:
    return "'<='";
  case IF:
    return "if";
  case ELSE:
    return "else";
  case ELIF:
    return "elif";
  case ENDIF:
    return "endif";
  case AND:
    return "and";
  case OR:
    return "or";
  case NOT:
    return "not";
  case FOREACH:
    return "foreach";
  case ENDFOREACH:
    return "endforeach";
  case IN:
    return "in";
  case CONTINUE:
    return "continue";
  case BREAK:
    return "break";
  case IDENTIFIER:
    return "identifier";
  case STRING:
    return "string";
  case NUMBER:
    return "number";
  case TRUE:
    return "true";
  case FALSE:
    return "false";
  case INVALID:
    return "<<error>>";
    break;
  }
  assert(false);
}

struct StringData {
public:
  bool format;
  bool multiline;
  std::string str;
};

struct NumberData {
public:
  int base;
  uint64_t asInt;
  std::string asString;
};

struct Token final {
public:
  uint32_t startLine;
  uint32_t startColumn;
  uint32_t endLine;
  uint32_t endColumn;
  std::variant<std::monostate, NumberData, std::string, StringData> dat;
  TokenType type = TokenType::INVALID;

  Token(uint32_t startLine, uint32_t startColumn)
      : startLine(startLine), startColumn(startColumn) {}
};

struct LexError final {
public:
  std::string message;
  uint32_t line;
  uint32_t column;
};

class Lexer final {
  enum class LexerResult {
    CONTINUE,
    FAIL,
    DONE,
  };

public:
  std::vector<Token> tokens;
  std::vector<LexError> errors;
  std::string input;
  uint32_t idx{0};
  uint32_t dataIdx = 0;
  uint32_t line = 0;
  uint32_t lineStart = 0;
  uint32_t parens = 0;
  uint32_t brackets = 0;
  uint32_t curls = 0;

  Lexer(const std::string &input) {
    this->idx = 0;
    this->input = input;
    this->input.push_back('\0');
    this->tokens.reserve(guessTokensCount(this->input.size()));
    assert(this->idx == 0);
  }

  bool tokenize();

  static size_t guessTokensCount(size_t inputSize) {
    return (size_t)((SLOPE * (double)inputSize) + Y_INTERCEPT);
  }

private:
  void advance();

  // These values were calculated using the lexerstats.cpp
  // tool. For the input set of 10k files it took pairs of
  // (fileSize, numTokens) and used linear regression to calculate
  // a formula. This is the result. This will optimise the number
  // of allocations needed for e.g. resizing.
  constexpr static auto SLOPE = 0.122;
  constexpr static auto Y_INTERCEPT = 31;

  LexerResult lexString(bool fString);
  LexerResult tokenizeOne();
  LexerResult lexStringChar(bool multiline, std::string &str);
  LexerResult lexIdentifier();
  LexerResult lexNumber();
  void finalize();
  void error(const std::string &msg);
  bool isKeyword(size_t startIdx, size_t len);
};
