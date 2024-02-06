#include "lexer.hpp"

#include "log.hpp"

#include <cstdint>
#include <exception>
#include <utility>

#ifdef NDEBUG
#undef NDEBUG
#endif
#include <cassert>
#include <cctype>
#include <format>
#include <map>
#include <string>

// Copied+adapted from muon (GPLv3)

const static Logger LOG("lexer"); // NOLINT

static const std::map<std::string, TokenType> /*NOLINT*/ KEYWORDS{
    {"and", TokenType::AND},
    {"break", TokenType::BREAK},
    {"continue", TokenType::CONTINUE},
    {"elif", TokenType::ELIF},
    {"else", TokenType::ELSE},
    {"endforeach", TokenType::ENDFOREACH},
    {"endif", TokenType::ENDIF},
    {"false", TokenType::FALSE},
    {"foreach", TokenType::FOREACH},
    {"if", TokenType::IF},
    {"in", TokenType::IN},
    {"not", TokenType::NOT},
    {"or", TokenType::OR},
    {"true", TokenType::TRUE}};

static bool isSkipchar(const char chr) {
  return chr == '\r' || chr == ' ' || chr == '\t' || chr == '#';
}

static bool isValidStartOfIdentifier(const char chr) {
  return chr == '_' || ('a' <= chr && chr <= 'z') || ('A' <= chr && chr <= 'Z');
}

static bool isDigit(const char chr) { return '0' <= chr && chr <= '9'; }

static bool isValidInsideOfIdentifier(const char chr) {
  return isValidStartOfIdentifier(chr) || isDigit(chr);
}

void Lexer::advance() {
  if (this->idx >= this->input.length()) {
    return;
  }
  if (this->input[this->idx] == '\n') {
    this->line++;
    this->lineStart = this->idx + 1;
  }
  this->idx++;
}

Lexer::LexerResult Lexer::lexNumber() {
  this->tokens.back().type = TokenType::NUMBER;
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
    case '0':
    case 'o':
      base = 8;
      this->advance();
      this->advance();
      break;
    default:
      this->advance();
      this->tokens.back().dat = NumberData{10, 0, "0"};
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
    LOG.error(std::format("stoull: {}", exc.what()));
    this->error("Invalid integer literal");
  }
  this->tokens.back().dat = NumberData{base, asInt, asStr};
  this->finalize();
  return LexerResult::CONTINUE;
}

Lexer::LexerResult Lexer::lexIdentifier() {
  auto startIdx = this->idx;
  auto len = 0;
  while (isValidInsideOfIdentifier(this->input[this->idx])) {
    len++;
    this->advance();
  }
  assert(len);
  auto name = this->input.substr(startIdx, len);
  if (!this->isKeyword(name)) {
    this->tokens.back().type = TokenType::IDENTIFIER;
    this->tokens.back().dat = name;
  }
  this->finalize();
  return LexerResult::CONTINUE;
}

bool Lexer::isKeyword(const std::string &name) {
  if (KEYWORDS.contains(name)) {
    auto type = KEYWORDS.at(name);
    this->tokens.back().type = type;
    return true;
  }
  return false;
}

Lexer::LexerResult Lexer::lexStringChar(bool multiline, std::string &str) {
  auto done = false;
  if (this->idx >= this->input.length()) {
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
    if (this->input[this->idx + 1] == '\'') {
      str.push_back('\\');
      this->advance();
      str.push_back('\'');
      break;
    }
    [[fallthrough]];
  default:
    str.push_back(this->input[this->idx]);
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
  if (this->input.substr(this->idx, 3) == "'''") {
    multiline = true;
    this->advance();
    this->advance();
    this->advance();
  } else {
    this->advance();
  }
  this->tokens.back().type = TokenType::STRING;
  std::string str;
  str.reserve(20);
  auto loop = true;
  auto ret = Lexer::LexerResult::CONTINUE;
  while (loop) {
    switch (this->lexStringChar(multiline, str)) {
    case Lexer::LexerResult::CONTINUE:
      break;
    case Lexer::LexerResult::DONE:
      loop = false;
      break;
    case Lexer::LexerResult::FAIL:
      auto terminated = false;
      while (this->idx < this->input.size() && (this->input[this->idx] != 0) &&
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

  this->tokens.back().dat = StringData{
      .format = fString, .multiline = multiline, .str = std::move(str)};
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
  auto tok = Token(this->line, this->idx - this->lineStart);
  this->tokens.push_back(tok);
  if (chr == 'f' && this->input[this->idx + 1] == '\'') {
    this->advance();
    return this->lexString(true);
  }
  if (chr == '\'') {
    return this->lexString(false);
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
    this->tokens.back().type = TokenType::EOL;
    break;
  case '(':
    this->parens++;
    this->tokens.back().type = TokenType::LPAREN;
    break;
  case ')':
    if (this->parens == 0) {
      this->error("Closing ')' without a matching opening '('");
      this->finalize();
      return LexerResult::FAIL;
    }
    this->parens--;
    this->tokens.back().type = TokenType::RPAREN;
    break;
  case '[':
    this->brackets++;
    this->tokens.back().type = TokenType::LBRACK;
    break;
  case ']':
    if (this->brackets == 0) {
      this->error("Closing ']' without a matching opening '['");
      this->finalize();
      return LexerResult::FAIL;
    }
    this->brackets--;
    this->tokens.back().type = TokenType::RBRACK;
    break;
  case '{':
    this->curls++;
    this->tokens.back().type = TokenType::LCURL;
    break;
  case '}':
    if (this->curls == 0) {
      this->error("Closing '}' without a matching opening '{'");
      this->finalize();
      return LexerResult::FAIL;
    }
    this->curls--;
    this->tokens.back().type = TokenType::RCURL;
    break;
  case '.':
    this->tokens.back().type = TokenType::DOT;
    break;
  case ',':
    this->tokens.back().type = TokenType::COMMA;
    break;
  case ':':
    this->tokens.back().type = TokenType::COLON;
    break;
  case '?':
    this->tokens.back().type = TokenType::QUESTION_MARK;
    break;
  case '+':
    if (this->input[this->idx + 1] == '=') {
      this->advance();
      this->tokens.back().type = TokenType::PLUS_ASSIGN;
    } else {
      this->tokens.back().type = TokenType::PLUS;
    }
    break;
  case '-':
    this->tokens.back().type = TokenType::MINUS;
    break;
  case '*':
    this->tokens.back().type = TokenType::STAR;
    break;
  case '/':
    this->tokens.back().type = TokenType::SLASH;
    break;
  case '%':
    this->tokens.back().type = TokenType::MODULO;
    break;
  case '=':
    if (this->input[this->idx + 1] == '=') {
      this->advance();
      this->tokens.back().type = TokenType::EQ;
    } else {
      this->tokens.back().type = TokenType::ASSIGN;
    }
    break;
  case '!':
    if (this->input[this->idx + 1] == '=') {
      this->advance();
      this->tokens.back().type = TokenType::NEQ;
    } else {
      this->error(
          std::format("Unexpected character: '%c'", this->input[this->idx]));
      this->finalize();
      return LexerResult::FAIL;
    }
    break;
  case '>':
    if (this->input[this->idx + 1] == '=') {
      this->advance();
      this->tokens.back().type = TokenType::GEQ;
    } else {
      this->tokens.back().type = TokenType::GT;
    }
    break;
  case '<':
    if (this->input[this->idx + 1] == '=') {
      this->advance();
      this->tokens.back().type = TokenType::LEQ;
    } else {
      this->tokens.back().type = TokenType::LT;
    }
    break;
  case '\0':
    if (this->idx != this->input.length() - 1) {
      LOG.info(std::format("{} {}\n{}", this->idx, this->input.length() - 1,
                           this->input));
      this->error("Unexpected null byte");
      this->finalize();
      return LexerResult::FAIL;
    }
    this->tokens.back().type = TokenType::TOKEOF;
    this->advance();
    this->finalize();
    return LexerResult::DONE;
  default:
    this->error(std::format("Unexpected character: '%c'", chr));
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
  auto len = this->input.length();
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
    assert(this->tokens.back().type == TokenType::TOKEOF);
  }
  return success;
}
