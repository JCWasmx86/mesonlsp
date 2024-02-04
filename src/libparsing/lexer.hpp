#pragma once
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
  std::variant<NumberData, std::string, StringData> dat;
  TokenType type = TokenType::INVALID;

  Token(uint32_t startLine, uint32_t startColumn)
      : startLine(startLine), startColumn(startColumn) {}
};

struct LexError final {
public:
  std::string msg;
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
  uint32_t idx = 0;
  uint32_t dataIdx = 0;
  uint32_t line = 0;
  uint32_t lineStart = 0;
  uint32_t parens = 0;
  uint32_t brackets = 0;
  uint32_t curls = 0;

  Lexer(const std::string &input) {
    this->input = input;
    this->input.push_back('\0');
    this->tokens.reserve(4096);
  }

  bool tokenize();

private:
  void advance();
  LexerResult lexString(bool fString);
  LexerResult tokenizeOne();
  LexerResult lexStringChar(bool multiline, std::string &str);
  LexerResult lexIdentifier();
  LexerResult lexNumber();
  void finalize();
  void error(const std::string &msg);
  bool isKeyword(const std::string &name);
};
