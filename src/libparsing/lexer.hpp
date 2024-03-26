#pragma once
#include <cassert>
#include <cstddef>
#include <cstdint>
#include <string>
#include <utility>
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
  std::unreachable();
}

struct IdentifierData {
public:
  std::string name;
  uint32_t hash;

  IdentifierData(std::string name, uint32_t hash)
      : name(std::move(name)), hash(hash) {}
};

struct StringData {
public:
  bool format;
  bool multiline;
  bool hasEnoughAts;
  bool doubleQuote;
  std::string str;

  StringData(bool format, bool multiline, bool hasEnoughAts, bool doubleQuote,
             std::string str)
      : format(format), multiline(multiline), hasEnoughAts(hasEnoughAts),
        doubleQuote(doubleQuote), str(std::move(str)) {}
};

struct NumberData {
public:
  uint64_t asInt;
  std::string asString;

  NumberData(uint64_t asInt, std::string asString)
      : asInt(asInt), asString(std::move(asString)) {}
};

struct Token final {
public:
  uint32_t startLine;
  uint32_t endLine;
  uint16_t startColumn;
  uint16_t endColumn;
  size_t idx;
  TokenType type = TokenType::INVALID;

  Token(uint32_t startLine, uint16_t startColumn)
      : startLine(startLine), startColumn(startColumn) {}
};

struct LexError final {
public:
  std::string message;
  uint32_t line;
  uint32_t column;

  LexError(std::string message, uint32_t line, uint32_t column)
      : message(std::move(message)), line(line), column(column) {}
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
  std::vector<NumberData> numberDatas;
  std::vector<StringData> stringDatas;
  std::vector<IdentifierData> identifierDatas;
  size_t inputSize;

  uint32_t idx = 0;
  uint32_t dataIdx = 0;
  uint32_t line = 0;
  uint32_t lineStart = 0;
  uint32_t parens = 0;
  uint32_t brackets = 0;
  uint32_t curls = 0;

  explicit Lexer(std::string input) : input(std::move(input)) {
    this->input.push_back('\0');
    this->inputSize = this->input.size();
    this->tokens.reserve(guessTokensCount(this->inputSize));
    this->numberDatas.reserve(guessNumbersCount(this->inputSize));
    this->identifierDatas.reserve(guessIdentifiersCount(this->inputSize));
    this->stringDatas.reserve(guessStringsCount(this->inputSize));
    assert(this->idx == 0);
  }

  bool tokenize();

  static size_t guessTokensCount(size_t inputSize) {
    return (size_t)((SLOPE * (double)inputSize) + Y_INTERCEPT);
  }

  static size_t guessNumbersCount(size_t inputSize) {
    return (size_t)((NUMBERS_SLOPE * (double)inputSize) + NUMBERS_Y_INTERCEPT);
  }

  static size_t guessIdentifiersCount(size_t inputSize) {
    return (size_t)((IDENTIFIERS_SLOPE * (double)inputSize) +
                    IDENTIFIERS_Y_INTERCEPT);
  }

  static size_t guessStringsCount(size_t inputSize) {
    return (size_t)((STRINGS_SLOPE * (double)inputSize) + STRINGS_Y_INTERCEPT);
  }

private:
  void advance() noexcept;

  // These values were calculated using the lexerstats.cpp
  // tool. For the input set of 10k files it took pairs of
  // (fileSize, numTokens) and used linear regression to calculate
  // a formula. This is the result. This will optimise the number
  // of allocations needed for e.g. resizing.
  constexpr static auto SLOPE = 0.122;
  constexpr static auto Y_INTERCEPT = 31;
  constexpr static auto NUMBERS_SLOPE = 0.001247;
  constexpr static auto NUMBERS_Y_INTERCEPT =
      0; // Should be -1, but that makes no sense
  constexpr static auto IDENTIFIERS_SLOPE = 0.026391;
  constexpr static auto IDENTIFIERS_Y_INTERCEPT = 6.8;
  constexpr static auto STRINGS_SLOPE = 0.01955;
  constexpr static auto STRINGS_Y_INTERCEPT = 3.65;

  LexerResult lexString(bool fString);
  LexerResult lexStringBad(bool fString);
  LexerResult lexStringCharBad(bool multiline, std::string &str,
                               uint32_t &nAts);
  LexerResult tokenizeOne();
  LexerResult lexStringChar(bool multiline, std::string &str, uint32_t &nAts);
  LexerResult lexIdentifier();
  LexerResult lexNumber();
  void finalize();
  void error(const std::string &msg);
  bool checkKeyword(size_t startIdx, size_t len);
};
