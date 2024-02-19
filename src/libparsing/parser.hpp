#pragma once
#include "lexer.hpp"
#include "node.hpp"
#include "polyfill.hpp"
#include "sourcefile.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <iostream>
#include <memory>
#include <optional>
#include <utility>

struct ParseError {
  std::string message;
  uint32_t line;
  uint32_t column;

  ParseError(std::string message, uint32_t line, uint32_t column)
      : message(std::move(message)), line(line), column(column) {}
};

class Parser {
public:
  const std::vector<Token> &tokens;
  const Lexer &lexer;
  size_t idx = 0;
  size_t inputLen = 0;
  std::vector<ParseError> errors;
  std::shared_ptr<SourceFile> sourceFile;

  Parser(const Lexer &lexer, const std::shared_ptr<SourceFile> &sourceFile)
      : tokens(lexer.tokens), lexer(lexer), sourceFile(sourceFile) {
    this->inputLen = this->tokens.size();
  }

  std::shared_ptr<Node> parse(const std::vector<LexError> &lexErrs);

private:
  std::vector<std::shared_ptr<Node>> codeBlock();
  std::optional<std::shared_ptr<Node>> line();
  std::shared_ptr<Node> ifBlock(const std::pair<uint32_t, uint32_t> &start);
  std::shared_ptr<Node>
  foreachBlock(const std::pair<uint32_t, uint32_t> &start);
  std::optional<std::shared_ptr<Node>> statement();
  std::optional<std::shared_ptr<Node>> e1();
  std::optional<std::shared_ptr<Node>> e2();
  std::optional<std::shared_ptr<Node>> e3();
  std::optional<std::shared_ptr<Node>> e4();
  std::optional<std::shared_ptr<Node>> e5();
  std::optional<std::shared_ptr<Node>> e6();
  std::optional<std::shared_ptr<Node>> e7();
  std::optional<std::shared_ptr<Node>> e8();
  std::optional<std::shared_ptr<Node>> e9();
  std::optional<std::shared_ptr<Node>> e5AddSub();
  std::optional<std::shared_ptr<Node>> e5MulDiv();
  std::vector<std::shared_ptr<Node>> keyValues();
  std::vector<std::shared_ptr<Node>> arrayArgs();
  std::shared_ptr<Node> args();
  std::shared_ptr<Node>
  methodCall(const std::optional<std::shared_ptr<Node>> &source);
  std::shared_ptr<Node>
  indexCall(const std::optional<std::shared_ptr<Node>> &source);

  void error(const std::string &error) {
    auto realIdx = std::min(this->idx, this->inputLen - 1);
    this->errors.emplace_back(error, this->tokens[realIdx].endLine,
                              this->tokens[realIdx].endColumn);
  }

  std::shared_ptr<Node>
  unwrap(const std::optional<std::shared_ptr<Node>> &input) {
    if (input.has_value()) {
      return input.value();
    }
    auto loc = this->currLoc();
    return std::make_shared<ErrorNode>(this->sourceFile, loc, loc,
                                       "Expected value");
  }

  std::pair<uint32_t, uint32_t> currLoc() {
    if (idx >= this->inputLen) {
      return std::make_pair(this->tokens.back().startLine,
                            this->tokens.back().startColumn);
    }
    return std::make_pair(this->tokens[idx].startLine,
                          this->tokens[idx].startColumn);
  }

  std::pair<uint32_t, uint32_t> endLoc() {
    if (idx >= this->inputLen) {
      return std::make_pair(this->tokens.back().endLine,
                            this->tokens.back().endColumn);
    }
    return std::make_pair(this->tokens[idx].endLine,
                          this->tokens[idx].endColumn);
  }

  void getsym() {
    if (this->idx >= this->inputLen) {
      return;
    }
    this->idx++;
  }

  bool accept(const TokenType type) {
    if (this->idx >= this->inputLen) {
      return false;
    }
    if (this->tokens[this->idx].type == type) {
      this->getsym();
      return true;
    }
    return false;
  }

  void dumpContext() {
    for (size_t i = idx - 3; i < std::min(idx + 5, this->inputLen - 1); i++) {
      std::cerr << std::format("[{}{}] TOKEN: {} [{}:{}]", i,
                               idx == i ? "*" : "", enum2String(tokens[i].type),
                               tokens[i].startLine, tokens[i].startColumn)
                << std::endl;
    }
  }

  void expect(const TokenType type) {
    if (this->accept(type)) {
      return;
    }
    if (this->idx >= this->inputLen) {
      this->error(std::format("Expected {}, but got {}", enum2String(type),
                              enum2String(this->tokens.back().type)));
      return;
    }
    this->error(std::format("Expected {}, but got {}", enum2String(type),
                            enum2String(this->tokens[idx].type)));
  }

  std::shared_ptr<Node> errorNode(const std::string &msg) {
    return std::make_shared<ErrorNode>(this->sourceFile, this->currLoc(),
                                       this->currLoc(), msg);
  }

  std::optional<std::shared_ptr<Node>> seekTo(TokenType type) {
    auto aLoc = this->currLoc();
    auto makeError = false;
    while (this->idx < this->inputLen) {
      if (this->tokens[idx].type != type) {
        makeError = true;
        this->idx++;
        continue;
      }
      break;
    }
    if (makeError) {
      return std::make_shared<ErrorNode>(this->sourceFile, aLoc,
                                         this->currLoc(), "Unexpected junk");
    }
    return std::nullopt;
  }

  std::optional<std::shared_ptr<Node>> seekToOverInvalidTokens() {
    auto aLoc = this->currLoc();
    auto makeError = false;
    while (this->idx < this->inputLen) {
      if (this->tokens[idx].type == TokenType::INVALID) {
        makeError = true;
        this->idx++;
        continue;
      }
      break;
    }
    if (makeError) {
      return std::make_shared<ErrorNode>(this->sourceFile, aLoc,
                                         this->currLoc(), "Unexpected tokens");
    }
    return std::nullopt;
  }
};
