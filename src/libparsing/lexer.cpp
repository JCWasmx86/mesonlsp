#include "lexer.hpp"

#include "log.hpp"
#include "utils.hpp"

#include <cstdint>
#include <exception>
#include <utility>

#ifdef NDEBUG
#undef NDEBUG
#endif
#include <cassert>
#include <cctype>
#include <format>
#include <string>

using enum TokenType;
using BoolFunction = bool (*)(char);

template <size_t N>
constexpr std::array<bool, N> generateBoolArray(BoolFunction func) {
  std::array<bool, N> result{};
  for (size_t i = 0; i < N; ++i) {
    result[i] = func(static_cast<char>(i));
  }
  return result;
}

// Copied+adapted from muon (GPLv3)

const static Logger LOG("lexer"); // NOLINT

// This is the average string length calculated using around
// 10k lines with the lexerstats tool (See the current directory)
// We can use this to optimise the amount of allocations+resizes needed
// in the average case.
constexpr auto AVERAGE_STRING_LENGTH = 16;

static const std::vector<
    std::tuple<std::string, TokenType, uint32_t>> /*NOLINT*/ KEYWORDS{
    {"if", IF, djb2("if")},
    {"endif", ENDIF, djb2("endif")},
    {"and", AND, djb2("and")},
    {"break", BREAK, djb2("break")},
    {"continue", CONTINUE, djb2("continue")},
    {"elif", ELIF, djb2("elif")},
    {"else", ELSE, djb2("else")},
    {"endforeach", ENDFOREACH, djb2("endforeach")},
    {"false", FALSE, djb2("false")},
    {"foreach", FOREACH, djb2("foreach")},
    {"in", IN, djb2("in")},
    {"not", NOT, djb2("not")},
    {"or", OR, djb2("or")},
    {"true", TRUE, djb2("true")}};

static bool isSkipchar(const char chr) {
  return chr == '\r' || chr == ' ' || chr == '\t' || chr == '#';
}

static constexpr bool isValidStartOfIdentifier(const char chr) {
  return chr == '_' || ('a' <= chr && chr <= 'z') || ('A' <= chr && chr <= 'Z');
}

static constexpr bool isDigit(const char chr) {
  return '0' <= chr && chr <= '9';
}

static constexpr bool isValidInsideOfIdentifier(const char chr) {
  return isValidStartOfIdentifier(chr) || isDigit(chr);
}

constexpr auto VALID_INSIDE_IDENTIFIER =
    generateBoolArray<256>(isValidInsideOfIdentifier);

void Lexer::advance() noexcept {
  if (this->idx >= this->inputSize) {
    return;
  }
  if (this->input[this->idx] == '\n') [[unlikely]] {
    this->line++;
    this->lineStart = this->idx + 1;
  }
  this->idx++;
}

Lexer::LexerResult Lexer::lexNumber() {
  this->tokens.back().type = NUMBER;
  auto base = 10;
  if (this->input[this->idx] == '0') {
    switch (this->input[this->idx + 1]) {
    case 'X':
    case 'x':
      base = 16;
      this->advance();
      this->advance();
      break;
    case 'B':
    case 'b':
      base = 2;
      this->advance();
      this->advance();
      break;
    case 'O':
    case 'o':
      base = 8;
      this->advance();
      this->advance();
      break;
    default:
      this->advance();
      this->numberDatas.emplace_back(0, "0");
      this->tokens.back().idx = this->numberDatas.size() - 1;
      this->finalize();
      return LexerResult::CONTINUE;
    }
  }
  std::string asStr;
  while (true) {
    auto chr = this->input[this->idx];
    switch (base) {
    case 2:
      if (chr == '0' || chr == '1') {
        asStr.push_back(chr);
        break;
      }
      goto end;
    case 8:
      if (chr >= '0' && chr <= '7') {
        asStr.push_back(chr);
        break;
      }
      goto end;
    case 10:
      if (chr >= '0' && chr <= '9') {
        asStr.push_back(chr);
        break;
      }
      goto end;
    case 16:
      if (std::isxdigit(chr) != 0) {
        asStr.push_back(chr);
        break;
      }
      goto end;
    default:
      std::unreachable();
    }
    this->advance();
  }
end:

  uint64_t asInt = 0;
  try {
    asInt = std::stoull(asStr, nullptr, base);
  } catch (const std::exception &exc) {
    LOG.error(std::format("Invalid integer literal for base {}: {}", base,
                          exc.what()));
    this->error("Invalid integer literal");
  }
  this->numberDatas.emplace_back(asInt, std::move(asStr));
  this->tokens.back().idx = this->numberDatas.size() - 1;
  this->finalize();
  return LexerResult::CONTINUE;
}

Lexer::LexerResult Lexer::lexIdentifier() {
  auto startIdx = this->idx;
  auto len = 0;
  while (
      VALID_INSIDE_IDENTIFIER[static_cast<uint8_t>(this->input[this->idx])]) {
    len++;
    this->advance();
  }
  assert(len);
  this->checkKeyword(startIdx, len);
  this->finalize();
  return LexerResult::CONTINUE;
}

bool Lexer::checkKeyword(size_t startIdx, size_t len) {
  auto hashed = djb2(&this->input[startIdx], len);
  for /*NOLINT*/ (const auto &[asStr, type, asHash] : KEYWORDS) {
    if (hashed != asHash) {
      continue;
    }
    if (this->input.compare(startIdx, len, asStr) == 0) {
      this->tokens.back().type = type;
      return true;
    }
  }
  this->tokens.back().type = IDENTIFIER;
  this->identifierDatas.emplace_back(
      std::string(static_cast<const char *>(&this->input[startIdx]), len),
      hashed);
  this->tokens.back().idx = this->identifierDatas.size() - 1;
  return false;
}

Lexer::LexerResult Lexer::lexStringChar(bool multiline, std::string &str,
                                        uint32_t &nAts) {
  auto done = false;
  if (this->idx >= this->inputSize) {
    return LexerResult::FAIL;
  }
  switch (this->input[this->idx]) {
  case '\n':
    if (multiline) {
      str.push_back(this->input[this->idx]);
      break;
    }
    return LexerResult::FAIL;
  case 0:
    return LexerResult::FAIL;
  case '\'':
    if (!multiline) {
      done = true;
      break;
    }
    if (this->input[this->idx + 1] == '\'' &&
        this->input[this->idx + 2] == '\'') {
      this->advance();
      this->advance();
      done = true;
    } else {
      str.push_back(this->input[this->idx]);
    }
    break;
  // Ignore
  case '\\':
    if (this->input[this->idx + 1] == '\\') {
      str.push_back('\\');
      this->advance();
      str.push_back('\\');
      break;
    }
    if (this->input[this->idx + 1] == '\'') {
      str.push_back('\\');
      this->advance();
      str.push_back('\'');
      break;
    }
    [[fallthrough]];
  [[likely]] default:
    auto chr = this->input[this->idx];
    if (chr == '@') [[unlikely]] {
      nAts++;
    }
    str.push_back(chr);
    break;
  }
  this->advance();

  if (done) {
    return LexerResult::DONE;
  }
  return LexerResult::CONTINUE;
}

Lexer::LexerResult Lexer::lexString(bool fString) {
  auto multiline = false;
  uint32_t quotes = 0;
  if (this->idx + 3 < this->inputSize &&
      this->input.compare(this->idx, 3, "'''") == 0) {
    multiline = true;
    this->advance();
    this->advance();
    this->advance();
  } else {
    this->advance();
  }
  this->tokens.back().type = STRING;
  std::string str;
  str.reserve(AVERAGE_STRING_LENGTH);
  auto loop = true;
  auto ret = Lexer::LexerResult::CONTINUE;
  uint32_t nAts = 0;
  while (loop) {
    switch (this->lexStringChar(multiline, str, nAts)) {
    case Lexer::LexerResult::CONTINUE:
      break;
    case Lexer::LexerResult::DONE:
      loop = false;
      break;
    case Lexer::LexerResult::FAIL:
      auto terminated = false;
      while (this->idx < this->inputSize && (this->input[this->idx] != 0) &&
             (multiline || (!multiline && this->input[this->idx] != '\n'))) {
        if (this->input[this->idx] == '\'') {
          quotes++;
          if ((multiline && quotes == 3) || (!multiline && quotes == 1)) {
            this->advance();
            terminated = true;
            break;
          }
          this->advance();
        }
      }
      if (!terminated) {
        this->error("Unterminated string");
      }
      loop = false;
      ret = LexerResult::FAIL;
      break;
    }
  }
  this->stringDatas.push_back({fString, multiline, nAts >= 2, std::move(str)});
  this->tokens.back().idx = this->stringDatas.size() - 1;
  this->finalize();
  return ret;
}

Lexer::LexerResult Lexer::tokenizeOne() {
  while (isSkipchar(this->input[this->idx])) {
    const auto chr = this->input[this->idx];
    if (chr != '#') [[likely]] {
      this->advance();
      continue;
    }
    this->advance();
    while ((this->input[this->idx] != 0) && this->input[this->idx] != '\n') {
      this->advance();
    }
  }
  const auto chr = this->input[this->idx];
  if (chr == '\\' && this->input[this->idx + 1] == '\n') {
    this->advance();
    this->advance();
    return this->tokenizeOne();
  }
  this->tokens.emplace_back(this->line, this->idx - this->lineStart);
  if (chr == '\'') {
    return this->lexString(false);
  }
  if (chr == 'f' && this->input[this->idx + 1] == '\'') {
    this->advance();
    return this->lexString(true);
  }
  if (isValidStartOfIdentifier(chr)) {
    return this->lexIdentifier();
  }
  if (isDigit(chr)) {
    return this->lexNumber();
  }
  switch (this->input[this->idx]) {
  case '\n':
    if ((this->parens != 0U) || (this->brackets != 0U) || (this->curls != 0U)) {
      goto skip;
    }
    this->tokens.back().type = EOL;
    break;
  case '(':
    this->parens++;
    this->tokens.back().type = LPAREN;
    break;
  case ')':
    if (this->parens == 0) {
      this->error("Closing ')' without a matching opening '('");
      this->finalize();
      return LexerResult::FAIL;
    }
    this->parens--;
    this->tokens.back().type = RPAREN;
    break;
  case '[':
    this->brackets++;
    this->tokens.back().type = LBRACK;
    break;
  case ']':
    if (this->brackets == 0) {
      this->error("Closing ']' without a matching opening '['");
      this->finalize();
      return LexerResult::FAIL;
    }
    this->brackets--;
    this->tokens.back().type = RBRACK;
    break;
  case '{':
    this->curls++;
    this->tokens.back().type = LCURL;
    break;
  case '}':
    if (this->curls == 0) {
      this->error("Closing '}' without a matching opening '{'");
      this->finalize();
      return LexerResult::FAIL;
    }
    this->curls--;
    this->tokens.back().type = RCURL;
    break;
  case '.':
    this->tokens.back().type = DOT;
    break;
  case ',':
    this->tokens.back().type = COMMA;
    break;
  case ':':
    this->tokens.back().type = COLON;
    break;
  case '?':
    this->tokens.back().type = QUESTION_MARK;
    break;
  case '+':
    if (this->input[this->idx + 1] == '=') {
      this->advance();
      this->tokens.back().type = PLUS_ASSIGN;
    } else {
      this->tokens.back().type = PLUS;
    }
    break;
  case '-':
    this->tokens.back().type = MINUS;
    break;
  case '*':
    this->tokens.back().type = STAR;
    break;
  case '/':
    this->tokens.back().type = SLASH;
    break;
  case '%':
    this->tokens.back().type = MODULO;
    break;
  case '=':
    if (this->input[this->idx + 1] == '=') {
      this->advance();
      this->tokens.back().type = EQ;
    } else {
      this->tokens.back().type = ASSIGN;
    }
    break;
  case '!':
    if (this->input[this->idx + 1] == '=') {
      this->advance();
      this->tokens.back().type = NEQ;
    } else {
      this->error(
          std::format("Unexpected character: '{}'", this->input[this->idx]));
      this->finalize();
      return LexerResult::FAIL;
    }
    break;
  case '>':
    if (this->input[this->idx + 1] == '=') {
      this->advance();
      this->tokens.back().type = GEQ;
    } else {
      this->tokens.back().type = GT;
    }
    break;
  case '<':
    if (this->input[this->idx + 1] == '=') {
      this->advance();
      this->tokens.back().type = LEQ;
    } else {
      this->tokens.back().type = LT;
    }
    break;
  case '\0':
    if (this->idx != this->inputSize - 1) {
      LOG.info(std::format("{} {}\n{}", this->idx, this->inputSize - 1,
                           this->input));
      this->error("Unexpected null byte");
      this->finalize();
      return LexerResult::FAIL;
    }
    this->tokens.back().type = TOKEOF;
    this->advance();
    this->finalize();
    return LexerResult::DONE;
  default:
    this->error(std::format("Unexpected character: '{}'", chr));
    return LexerResult::FAIL;
  }
  this->advance();
  this->finalize();
  return LexerResult::CONTINUE;

skip:
  this->advance();
  this->tokens.pop_back();
  return LexerResult::CONTINUE;
}

void Lexer::finalize() {
  this->tokens.back().endLine = this->line;
  this->tokens.back().endColumn = this->idx - this->lineStart;
}

void Lexer::error(const std::string &msg) {
  this->errors.emplace_back(msg, this->line, this->idx - this->lineStart);
}

bool Lexer::tokenize() {
  auto success = true;
  auto loop = true;
  auto len = this->inputSize;
  while (loop && this->idx < len) {
    auto result = this->tokenizeOne();
    switch (result) {
    case LexerResult::CONTINUE:
      break;
    case LexerResult::FAIL:
      success = false;
      this->advance();
      break;
    case LexerResult::DONE:
      loop = false;
      break;
    }
  }
  if (success) {
    assert(this->tokens.back().type == TOKEOF);
  }
  return success;
}
