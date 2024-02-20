#include "parser.hpp"

#include "lexer.hpp"
#include "location.hpp"
#include "log.hpp"
#include "node.hpp"

#include <memory>
#include <optional>

const static Logger LOG("parser"); // NOLINT

using enum TokenType;

std::shared_ptr<Node> Parser::parse(const std::vector<LexError> &lexErrs) {
  auto before = this->currLoc();
  auto block = this->codeBlock();
  auto after = this->currLoc();
  this->expect(TOKEOF);
  std::vector<ParsingError> errs;
  errs.reserve(this->errors.size() + lexErrs.size());
  for (const auto &err : this->errors) {
    errs.emplace_back(Location(err.line, err.line, err.column, err.column),
                      err.message);
  }
  for (const auto &err : lexErrs) {
    errs.emplace_back(Location(err.line, err.line, err.column, err.column),
                      err.message);
  }
  return std::make_shared<BuildDefinition>(this->sourceFile, block, before,
                                           after, errs);
}

std::optional<std::shared_ptr<Node>> Parser::statement() { return this->e1(); }

std::optional<std::shared_ptr<Node>> Parser::e1() {
  auto left = this->e2();
  if (!left.has_value()) {
    return left;
  }
  if (this->accept(PLUS_ASSIGN)) {
    auto value = this->e1();
    return std::make_shared<AssignmentStatement>(
        this->sourceFile, this->unwrap(left), this->unwrap(value),
        AssignmentOperator::PLUS_EQUALS);
  }
  if (this->accept(ASSIGN)) {
    auto value = this->e1();
    return std::make_shared<AssignmentStatement>(
        this->sourceFile, this->unwrap(left), this->unwrap(value),
        AssignmentOperator::EQUALS);
  }

  if (this->accept(QUESTION_MARK)) {
    auto trueBlock = this->e1();
    this->expect(COLON);
    auto falseBlock = this->e1();
    return std::make_shared<ConditionalExpression>(
        this->sourceFile, this->unwrap(left), this->unwrap(trueBlock),
        this->unwrap(falseBlock));
  }

  return left;
}

std::optional<std::shared_ptr<Node>> Parser::e2() {
  auto left = this->e3();
  if (!left.has_value()) {
    return left;
  }
  while (this->accept(OR)) {
    left = std::make_shared<BinaryExpression>(
        this->sourceFile, this->unwrap(left), this->unwrap(this->e3()),
        BinaryOperator::OR);
  }
  return left;
}

std::optional<std::shared_ptr<Node>> Parser::e3() {
  auto left = this->e4();
  while (this->accept(AND)) {
    left = std::make_shared<BinaryExpression>(
        this->sourceFile, this->unwrap(left), this->unwrap(this->e3()),
        BinaryOperator::AND);
  }
  return left;
}

// == != < <= > >= in not in

std::optional<std::shared_ptr<Node>> Parser::e4() {
  auto left = this->e5();
  if (this->accept(EQ)) {
    return std::make_shared<BinaryExpression>(
        this->sourceFile, this->unwrap(left), this->unwrap(this->e5()),
        BinaryOperator::EQUALS_EQUALS);
  }
  if (this->accept(NEQ)) {
    return std::make_shared<BinaryExpression>(
        this->sourceFile, this->unwrap(left), this->unwrap(this->e5()),
        BinaryOperator::NOT_EQUALS);
  }
  if (this->accept(LT)) {
    return std::make_shared<BinaryExpression>(
        this->sourceFile, this->unwrap(left), this->unwrap(this->e5()),
        BinaryOperator::LT);
  }
  if (this->accept(LEQ)) {
    return std::make_shared<BinaryExpression>(
        this->sourceFile, this->unwrap(left), this->unwrap(this->e5()),
        BinaryOperator::LE);
  }
  if (this->accept(GT)) {
    return std::make_shared<BinaryExpression>(
        this->sourceFile, this->unwrap(left), this->unwrap(this->e5()),
        BinaryOperator::GT);
  }
  if (this->accept(GEQ)) {
    return std::make_shared<BinaryExpression>(
        this->sourceFile, this->unwrap(left), this->unwrap(this->e5()),
        BinaryOperator::GE);
  }
  if (this->accept(IN)) {
    return std::make_shared<BinaryExpression>(
        this->sourceFile, this->unwrap(left), this->unwrap(this->e5()),
        BinaryOperator::IN);
  }
  if (this->accept(NOT) && this->accept(IN)) {
    return std::make_shared<BinaryExpression>(
        this->sourceFile, this->unwrap(left), this->unwrap(this->e5()),
        BinaryOperator::NOT_IN);
  }
  return left;
}

std::optional<std::shared_ptr<Node>> Parser::e5() { return this->e5AddSub(); }

std::optional<std::shared_ptr<Node>> Parser::e5AddSub() {
  auto left = this->e5MulDiv();
  if (!left.has_value()) {
    return left;
  }
  while (true) {
    if (idx >= this->inputLen) {
      return std::make_shared<BinaryExpression>(
          this->sourceFile, this->unwrap(left),
          this->errorNode("Unexpected EOF"), BinaryOperator::BIN_OP_OTHER);
    }
    auto current = this->tokens[idx].type;
    // HACKY
    if (current == PLUS) {
      this->accept(current);
      left = std::make_shared<BinaryExpression>(
          this->sourceFile, this->unwrap(left), this->unwrap(this->e5MulDiv()),
          BinaryOperator::PLUS);
    } else if (current == MINUS) {
      this->accept(current);
      left = std::make_shared<BinaryExpression>(
          this->sourceFile, this->unwrap(left), this->unwrap(this->e5MulDiv()),
          BinaryOperator::MINUS);
    } else {
      break;
    }
  }
  return left;
}

std::optional<std::shared_ptr<Node>> Parser::e5MulDiv() {
  auto left = this->e6();
  if (!left.has_value()) {
    return left;
  }
  while (true) {
    if (idx >= this->inputLen) {
      return std::make_shared<BinaryExpression>(
          this->sourceFile, this->unwrap(left),
          this->errorNode("Unexpected EOF"), BinaryOperator::BIN_OP_OTHER);
    }
    auto current = this->tokens[idx].type;
    // HACKY
    if (current == MODULO) {
      this->accept(current);
      left = std::make_shared<BinaryExpression>(
          this->sourceFile, this->unwrap(left), this->unwrap(this->e6()),
          BinaryOperator::MODULO);
    } else if (current == STAR) {
      this->accept(current);
      left = std::make_shared<BinaryExpression>(
          this->sourceFile, this->unwrap(left), this->unwrap(this->e6()),
          BinaryOperator::MUL);
    } else if (current == SLASH) {
      this->accept(current);
      left = std::make_shared<BinaryExpression>(
          this->sourceFile, this->unwrap(left), this->unwrap(this->e6()),
          BinaryOperator::DIV);
    } else {
      break;
    }
  }
  return left;
}

std::optional<std::shared_ptr<Node>> Parser::e6() {
  auto currLoc = this->currLoc();
  if (this->accept(NOT)) {
    return std::make_shared<UnaryExpression>(this->sourceFile, currLoc,
                                             UnaryOperator::NOT,
                                             this->unwrap(this->e7()));
  }
  if (this->accept(MINUS)) {
    return std::make_shared<UnaryExpression>(this->sourceFile, currLoc,
                                             UnaryOperator::UNARY_MINUS,
                                             this->unwrap(this->e7()));
  }
  return this->e7();
}

std::optional<std::shared_ptr<Node>> Parser::e7() {
  auto left = this->e8();
  if (!left.has_value()) {
    return left;
  }
  if (this->accept(LPAREN)) {
    auto args = this->args();
    auto end = this->endLoc();
    this->expect(RPAREN);
    left = std::make_shared<FunctionExpression>(
        this->sourceFile, this->unwrap(left), this->unwrap(args), end);
  }
  auto goAgain = true;
  while (goAgain) {
    goAgain = false;
    if (this->accept(DOT)) {
      goAgain = true;
      left = this->methodCall(left);
    }
    if (this->accept(LBRACK)) {
      goAgain = true;
      left = this->indexCall(left);
    }
  }
  return left;
}

std::shared_ptr<Node>
Parser::indexCall(const std::optional<std::shared_ptr<Node>> &source) {
  auto index = this->statement();
  auto end = this->endLoc();
  this->expect(RBRACK);
  return std::make_shared<SubscriptExpression>(
      this->sourceFile, this->unwrap(source), this->unwrap(index), end);
}

std::optional<std::shared_ptr<Node>> Parser::e8() {
  if (this->accept(LPAREN)) {
    // TODO: We should update the location here to include the ()
    auto inner = this->statement();
    this->expect(RPAREN);
    return inner;
  }
  auto start = this->currLoc();
  if (this->accept(LBRACK)) {
    auto args = this->arrayArgs();
    auto end = this->currLoc();
    this->expect(RBRACK);
    return std::make_shared<ArrayLiteral>(this->sourceFile, args, start, end);
  }
  if (this->accept(LCURL)) {
    auto args = this->keyValues();
    auto end = this->currLoc();
    this->expect(RCURL);
    return std::make_shared<DictionaryLiteral>(this->sourceFile, args, start,
                                               end);
  }
  return this->e9();
}

std::vector<std::shared_ptr<Node>> Parser::arrayArgs() {
  std::vector<std::shared_ptr<Node>> ret;
  auto stmt = this->statement();
  while (stmt.has_value()) {
    if (this->accept(COMMA)) {
      ret.push_back(stmt.value());
    } else {
      ret.push_back(stmt.value());
      auto seeked = this->seekTo(RBRACK);
      if (seeked.has_value()) {
        ret.push_back(seeked.value());
      }
      return ret;
    }
    stmt = this->statement();
  }
  this->accept(COMMA);
  auto seeked = this->seekTo(RBRACK);
  if (seeked.has_value()) {
    ret.push_back(seeked.value());
  }
  return ret;
}

std::vector<std::shared_ptr<Node>> Parser::keyValues() {
  std::vector<std::shared_ptr<Node>> ret;
  auto stmt = this->statement();
  while (stmt.has_value()) {
    if (this->accept(COLON)) {
      ret.push_back(std::make_shared<KeyValueItem>(
          this->sourceFile, stmt.value(), this->unwrap(this->statement())));
      if (!this->accept(COMMA)) {
        return ret;
      }
    } else {
      this->error("Only key:value pairs are valid in dict construction.");
      auto seeked = this->seekTo(RCURL);
      if (seeked.has_value()) {
        ret.push_back(seeked.value());
      }
      return ret;
    }
    stmt = this->statement();
  }
  this->accept(COMMA);
  auto seeked = this->seekTo(RCURL);
  if (seeked.has_value()) {
    ret.push_back(seeked.value());
  }
  return ret;
}

std::optional<std::shared_ptr<Node>> Parser::e9() {
  auto start = this->currLoc();
  auto end = this->endLoc();
  if (this->accept(TRUE)) {
    return std::make_shared<BooleanLiteral>(this->sourceFile, start, end, true);
  }
  if (this->accept(FALSE)) {
    return std::make_shared<BooleanLiteral>(this->sourceFile, start, end,
                                            false);
  }
  if (idx >= this->inputLen) {
    return this->errorNode("Premature EOF");
  }
  const auto &curr = this->tokens[idx];
  if (this->accept(IDENTIFIER)) {
    const auto &idData = this->lexer.identifierDatas[curr.idx];
    return std::make_shared<IdExpression>(this->sourceFile, idData.name,
                                          idData.hash, start, end);
  }
  if (this->accept(NUMBER)) {
    const auto &intData = this->lexer.numberDatas[curr.idx];
    return std::make_shared<IntegerLiteral>(this->sourceFile, intData.asInt,
                                            intData.asString, start, end);
  }
  if (this->accept(STRING)) {
    const auto &strData = this->lexer.stringDatas[curr.idx];
    return std::make_shared<StringLiteral>(this->sourceFile, strData.str, start,
                                           end, strData.format,
                                           strData.hasEnoughAts);
  }
  if (this->accept(INVALID)) {
    return std::make_shared<ErrorNode>(this->sourceFile, start, end,
                                       "Invalid or unexpected token.");
  }
  return std::nullopt;
}

std::shared_ptr<Node>
Parser::methodCall(const std::optional<std::shared_ptr<Node>> &source) {
  auto name = this->e9();
  this->expect(LPAREN);
  auto args = this->args();
  auto end = this->endLoc();
  this->expect(RPAREN);
  auto node = std::make_shared<MethodExpression>(
      this->sourceFile, this->unwrap(source), this->unwrap(name), args, end);
  if (this->accept(DOT)) {
    return this->methodCall(node);
  }
  return node;
}

std::shared_ptr<Node> Parser::args() {
  auto before = this->currLoc();
  auto end = this->endLoc();
  auto stmt = this->statement();
  if (!stmt.has_value()) {
    return nullptr;
  }
  std::vector<std::shared_ptr<Node>> ret;
  while (stmt.has_value()) {
    if (this->accept(COMMA)) {
      ret.push_back(stmt.value());
    } else if (this->accept(COLON)) {
      ret.push_back(std::make_shared<KeywordItem>(
          this->sourceFile, stmt.value(), this->unwrap(this->statement())));
      if (!this->accept(COMMA)) {
        auto seeked = this->seekTo(RPAREN);
        if (seeked.has_value()) {
          ret.push_back(seeked.value());
        }
        return std::make_shared<ArgumentList>(this->sourceFile, ret, before,
                                              this->currLoc());
      }
    } else {
      ret.push_back(stmt.value());
      return std::make_shared<ArgumentList>(this->sourceFile, ret, before,
                                            this->endLoc());
    }
    stmt = this->statement();
    if (!stmt.has_value()) {
      break;
    }
    end = this->currLoc();
  }
  auto seeked = this->seekTo(RPAREN);
  if (seeked.has_value()) {
    ret.push_back(seeked.value());
  }
  return std::make_shared<ArgumentList>(this->sourceFile, ret, before, end);
}

std::optional<std::shared_ptr<Node>> Parser::line() {
  if (idx >= this->inputLen) {
    return this->errorNode("Unexpected EOF");
  }
  auto currentType = this->tokens[this->idx].type;
  if (currentType == EOL) {
    return std::nullopt;
  }
  auto start = this->currLoc();
  if (this->accept(IF)) {
    return this->ifBlock(start);
  }
  if (this->accept(FOREACH)) {
    return this->foreachBlock(start);
  }
  auto end = this->endLoc();
  if (this->accept(CONTINUE)) {
    return std::make_shared<ContinueNode>(this->sourceFile, start, end);
  }
  if (this->accept(BREAK)) {
    return std::make_shared<BreakNode>(this->sourceFile, start, end);
  }
  return this->statement();
}

std::shared_ptr<Node>
Parser::ifBlock(const std::pair<uint32_t, uint32_t> &start) {
  std::vector<std::shared_ptr<Node>> conditions;
  std::vector<std::vector<std::shared_ptr<Node>>> blocks;
  auto condition = this->statement();
  conditions.push_back(this->unwrap(condition));
  auto firstErr = this->seekToOverInvalidTokens();
  this->expect(EOL);
  auto block = this->codeBlock();
  blocks.push_back(block);
  if (firstErr.has_value()) {
    blocks.back().push_back(firstErr.value());
  }
  while (this->accept(ELIF)) {
    condition = this->statement();
    conditions.push_back(this->unwrap(condition));
    auto err = this->seekToOverInvalidTokens();
    this->expect(EOL);
    blocks.push_back(this->codeBlock());
    if (err.has_value()) {
      blocks.back().push_back(err.value());
    }
  }
  if (this->accept(ELSE)) {
    auto err = this->seekToOverInvalidTokens();
    this->expect(EOL);
    blocks.push_back(this->codeBlock());
    if (err.has_value()) {
      blocks.back().push_back(err.value());
    }
  }
  auto endLoc = this->endLoc();
  auto toEndif = this->seekTo(ENDIF);
  if (toEndif.has_value()) {
    if (!blocks.empty()) {
      blocks.back().push_back(toEndif.value());
    } else {
      LOG.warn("This code is absolutely messed up");
    }
  }
  this->expect(ENDIF);
  return std::make_shared<SelectionStatement>(this->sourceFile, conditions,
                                              blocks, start, endLoc);
}

std::shared_ptr<Node>
Parser::foreachBlock(const std::pair<uint32_t, uint32_t> &start) {
  std::vector<std::shared_ptr<Node>> ids;
  if (idx >= this->inputLen) {
    return this->errorNode("Premature EOF");
  }
  auto curr = this->tokens[idx];
  auto startOfIdExpr = this->currLoc();
  auto end = this->endLoc();
  this->expect(IDENTIFIER);
  if (curr.type == IDENTIFIER) {
    const auto &idData = this->lexer.identifierDatas[curr.idx];
    ids.push_back(std::make_shared<IdExpression>(
        this->sourceFile, idData.name, idData.hash, startOfIdExpr, end));
  }
  if (this->accept(COMMA)) {
    startOfIdExpr = this->currLoc();
    end = this->endLoc();
    if (idx >= this->inputLen) {
      return this->errorNode("Premature EOF");
    }
    curr = this->tokens[idx];
    this->expect(IDENTIFIER);
    const auto &idData = this->lexer.identifierDatas[curr.idx];
    if (curr.type == IDENTIFIER) {
      ids.push_back(std::make_shared<IdExpression>(
          this->sourceFile, idData.name, idData.hash, startOfIdExpr, end));
    }
  }
  std::vector<std::shared_ptr<Node>> errs;
  auto err = this->seekTo(COLON);
  if (err.has_value()) {
    errs.push_back(err.value());
  }
  this->expect(COLON);
  auto items = this->statement();
  err = this->seekTo(EOL);
  if (err.has_value()) {
    errs.push_back(err.value());
  }
  this->expect(EOL);
  auto block = this->codeBlock();
  end = this->endLoc();
  err = this->seekTo(ENDFOREACH);
  if (err.has_value()) {
    errs.push_back(err.value());
  }
  block.insert(block.end(), errs.begin(), errs.end());
  this->expect(ENDFOREACH);
  return std::make_shared<IterationStatement>(
      this->sourceFile, ids, this->unwrap(items), block, start, end);
}

std::vector<std::shared_ptr<Node>> Parser::codeBlock() {
  std::vector<std::shared_ptr<Node>> ret;
  auto cond = true;
  while (cond) {
    auto line = this->line();
    if (line.has_value()) {
      ret.push_back(line.value());
    }
    auto err = this->seekToOverInvalidTokens();
    if (err.has_value()) {
      ret.push_back(err.value());
    }
    cond = this->accept(EOL);
  }
  return ret;
}
