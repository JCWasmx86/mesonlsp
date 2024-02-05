#include "parser.hpp"

#include "lexer.hpp"
#include "log.hpp"
#include "node.hpp"

#include <memory>
#include <optional>

const static Logger LOG("parser"); // NOLINT

std::shared_ptr<Node> Parser::parse() {
  auto before = this->currLoc();
  auto block = this->codeBlock();
  auto after = this->currLoc();
  this->expect(TokenType::TOKEOF);
  return std::make_shared<BuildDefinition>(this->sourceFile, block, before,
                                           after);
}

std::optional<std::shared_ptr<Node>> Parser::statement() { return this->e1(); }

std::optional<std::shared_ptr<Node>> Parser::e1() {
  auto left = this->e2();
  if (!left.has_value()) {
    return left;
  }
  if (this->accept(TokenType::PLUS_ASSIGN)) {
    auto value = this->e1();
    return std::make_shared<AssignmentStatement>(
        this->sourceFile, this->unwrap(left), this->unwrap(value),
        AssignmentOperator::PLUS_EQUALS);
  }
  if (this->accept(TokenType::ASSIGN)) {
    auto value = this->e1();
    return std::make_shared<AssignmentStatement>(
        this->sourceFile, this->unwrap(left), this->unwrap(value),
        AssignmentOperator::EQUALS);
  }

  if (this->accept(TokenType::QUESTION_MARK)) {
    auto trueBlock = this->e1();
    this->expect(TokenType::COLON);
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
  while (this->accept(TokenType::OR)) {
    left = std::make_shared<BinaryExpression>(
        this->sourceFile, this->unwrap(left), this->unwrap(this->e3()),
        BinaryOperator::OR);
  }
  return left;
}

std::optional<std::shared_ptr<Node>> Parser::e3() {
  auto left = this->e4();
  while (this->accept(TokenType::AND)) {
    left = std::make_shared<BinaryExpression>(
        this->sourceFile, this->unwrap(left), this->unwrap(this->e3()),
        BinaryOperator::AND);
  }
  return left;
}

// == != < <= > >= in not in

std::optional<std::shared_ptr<Node>> Parser::e4() {
  auto left = this->e5();
  if (this->accept(TokenType::EQ)) {
    return std::make_shared<BinaryExpression>(
        this->sourceFile, this->unwrap(left), this->unwrap(this->e5()),
        BinaryOperator::EQUALS_EQUALS);
  }
  if (this->accept(TokenType::NEQ)) {
    return std::make_shared<BinaryExpression>(
        this->sourceFile, this->unwrap(left), this->unwrap(this->e5()),
        BinaryOperator::NOT_EQUALS);
  }
  if (this->accept(TokenType::LT)) {
    return std::make_shared<BinaryExpression>(
        this->sourceFile, this->unwrap(left), this->unwrap(this->e5()),
        BinaryOperator::LT);
  }
  if (this->accept(TokenType::LEQ)) {
    return std::make_shared<BinaryExpression>(
        this->sourceFile, this->unwrap(left), this->unwrap(this->e5()),
        BinaryOperator::LE);
  }
  if (this->accept(TokenType::GT)) {
    return std::make_shared<BinaryExpression>(
        this->sourceFile, this->unwrap(left), this->unwrap(this->e5()),
        BinaryOperator::GT);
  }
  if (this->accept(TokenType::GEQ)) {
    return std::make_shared<BinaryExpression>(
        this->sourceFile, this->unwrap(left), this->unwrap(this->e5()),
        BinaryOperator::GE);
  }
  if (this->accept(TokenType::IN)) {
    return std::make_shared<BinaryExpression>(
        this->sourceFile, this->unwrap(left), this->unwrap(this->e5()),
        BinaryOperator::IN);
  }
  if (this->accept(TokenType::NOT)) {
    if (this->accept(TokenType::IN)) {
      return std::make_shared<BinaryExpression>(
          this->sourceFile, this->unwrap(left), this->unwrap(this->e5()),
          BinaryOperator::NOT_IN);
    }
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
    if (idx >= this->tokens.size()) {
      return std::make_shared<BinaryExpression>(
          this->sourceFile, this->unwrap(left),
          this->errorNode("Unexpected EOF"), BinaryOperator::BIN_OP_OTHER);
    }
    auto current = this->tokens[idx].type;
    // HACKY
    if (current == TokenType::PLUS) {
      this->accept(current);
      left = std::make_shared<BinaryExpression>(
          this->sourceFile, this->unwrap(left), this->unwrap(this->e5MulDiv()),
          BinaryOperator::PLUS);
    } else if (current == TokenType::MINUS) {
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
    if (idx >= this->tokens.size()) {
      return std::make_shared<BinaryExpression>(
          this->sourceFile, this->unwrap(left),
          this->errorNode("Unexpected EOF"), BinaryOperator::BIN_OP_OTHER);
    }
    auto current = this->tokens[idx].type;
    // HACKY
    if (current == TokenType::MODULO) {
      this->accept(current);
      left = std::make_shared<BinaryExpression>(
          this->sourceFile, this->unwrap(left), this->unwrap(this->e6()),
          BinaryOperator::MODULO);
    } else if (current == TokenType::STAR) {
      this->accept(current);
      left = std::make_shared<BinaryExpression>(
          this->sourceFile, this->unwrap(left), this->unwrap(this->e6()),
          BinaryOperator::MUL);
    } else if (current == TokenType::SLASH) {
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
  if (this->accept(TokenType::NOT)) {
    return std::make_shared<UnaryExpression>(this->sourceFile, currLoc,
                                             UnaryOperator::NOT,
                                             this->unwrap(this->e7()));
  }
  if (this->accept(TokenType::MINUS)) {
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
  if (this->accept(TokenType::LPAREN)) {
    auto args = this->args();
    auto end = this->endLoc();
    this->expect(TokenType::RPAREN);
    left = std::make_shared<FunctionExpression>(
        this->sourceFile, this->unwrap(left), this->unwrap(args), end);
  }
  auto goAgain = true;
  while (goAgain) {
    goAgain = false;
    if (this->accept(TokenType::DOT)) {
      goAgain = true;
      left = this->methodCall(left);
    }
    if (this->accept(TokenType::LBRACK)) {
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
  this->expect(TokenType::RBRACK);
  return std::make_shared<SubscriptExpression>(
      this->sourceFile, this->unwrap(source), this->unwrap(index), end);
}

std::optional<std::shared_ptr<Node>> Parser::e8() {
  if (this->accept(TokenType::LPAREN)) {
    // TODO: We should update the location here to include the ()
    auto inner = this->statement();
    this->expect(TokenType::RPAREN);
    return inner;
  }
  auto start = this->currLoc();
  if (this->accept(TokenType::LBRACK)) {
    auto args = this->arrayArgs();
    auto end = this->currLoc();
    this->expect(TokenType::RBRACK);
    return std::make_shared<ArrayLiteral>(this->sourceFile, args, start, end);
  }
  if (this->accept(TokenType::LCURL)) {
    auto args = this->keyValues();
    auto end = this->currLoc();
    this->expect(TokenType::RCURL);
    return std::make_shared<DictionaryLiteral>(this->sourceFile, args, start,
                                               end);
  }
  return this->e9();
}

std::vector<std::shared_ptr<Node>> Parser::arrayArgs() {
  std::vector<std::shared_ptr<Node>> ret;
  auto stmt = this->statement();
  while (stmt.has_value()) {
    if (this->accept(TokenType::COMMA)) {
      ret.push_back(stmt.value());
    } else {
      ret.push_back(stmt.value());
      return ret;
    }
    stmt = this->statement();
  }
  this->accept(TokenType::COMMA);
  return ret;
}

std::vector<std::shared_ptr<Node>> Parser::keyValues() {
  std::vector<std::shared_ptr<Node>> ret;
  auto stmt = this->statement();
  while (stmt.has_value()) {
    if (this->accept(TokenType::COLON)) {
      ret.push_back(std::make_shared<KeyValueItem>(
          this->sourceFile, stmt.value(), this->unwrap(this->statement())));
      if (!this->accept(TokenType::COMMA)) {
        return ret;
      }
    } else {
      this->error("Only key:value pairs are valid in dict construction.");
      return ret;
    }
    stmt = this->statement();
  }
  this->accept(TokenType::COMMA);
  return ret;
}

std::optional<std::shared_ptr<Node>> Parser::e9() {
  auto start = this->currLoc();
  auto end = this->endLoc();
  if (this->accept(TokenType::TRUE)) {
    return std::make_shared<BooleanLiteral>(this->sourceFile, start, end, true);
  }
  if (this->accept(TokenType::FALSE)) {
    return std::make_shared<BooleanLiteral>(this->sourceFile, start, end,
                                            false);
  }
  if (idx >= this->tokens.size()) {
    return this->errorNode("Premature EOF");
  }
  const auto &curr = this->tokens[idx];
  if (this->accept(TokenType::IDENTIFIER)) {
    return std::make_shared<IdExpression>(
        this->sourceFile, std::get<std::string>(curr.dat), start, end);
  }
  if (this->accept(TokenType::NUMBER)) {
    const auto &intData = std::get<NumberData>(curr.dat);
    return std::make_shared<IntegerLiteral>(this->sourceFile, intData.asInt,
                                            intData.asString, start, end);
  }
  if (this->accept(TokenType::STRING)) {
    const auto &strData = std::get<StringData>(curr.dat);
    return std::make_shared<StringLiteral>(this->sourceFile, strData.str, start,
                                           end, strData.format);
  }
  return std::nullopt;
}

std::shared_ptr<Node>
Parser::methodCall(const std::optional<std::shared_ptr<Node>> &source) {
  auto name = this->e9();
  this->expect(TokenType::LPAREN);
  auto args = this->args();
  auto end = this->endLoc();
  this->expect(TokenType::RPAREN);
  auto node = std::make_shared<MethodExpression>(
      this->sourceFile, this->unwrap(source), this->unwrap(name), args, end);
  if (this->accept(TokenType::DOT)) {
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
    if (this->accept(TokenType::COMMA)) {
      auto tok = tokens[idx];
      ret.push_back(stmt.value());
    } else if (this->accept(TokenType::COLON)) {
      auto tok = tokens[idx];
      ret.push_back(std::make_shared<KeywordItem>(
          this->sourceFile, stmt.value(), this->unwrap(this->statement())));
      if (!this->accept(TokenType::COMMA)) {
        return std::make_shared<ArgumentList>(this->sourceFile, ret, before,
                                              this->currLoc());
      }
    } else {
      ret.emplace_back(stmt.value());
      return std::make_shared<ArgumentList>(this->sourceFile, ret, before,
                                            this->endLoc());
    }
    stmt = this->statement();
    if (!stmt.has_value()) {
      auto tok = tokens[idx];
      break;
    }
    end = this->currLoc();
  }
  return std::make_shared<ArgumentList>(this->sourceFile, ret, before, end);
}

std::optional<std::shared_ptr<Node>> Parser::line() {
  if (idx >= this->tokens.size()) {
    return this->errorNode("Unexpected EOF");
  }
  auto currentType = this->tokens[this->idx].type;
  if (currentType == TokenType::EOL) {
    return std::nullopt;
  }
  auto start = this->currLoc();
  if (this->accept(TokenType::IF)) {
    return this->ifBlock(start);
  }
  if (this->accept(TokenType::FOREACH)) {
    return this->foreachBlock(start);
  }
  auto end = this->endLoc();
  if (this->accept(TokenType::CONTINUE)) {
    return std::make_shared<ContinueNode>(this->sourceFile, start, end);
  }
  if (this->accept(TokenType::BREAK)) {
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
  this->expect(TokenType::EOL);
  auto block = this->codeBlock();
  blocks.push_back(block);
  while (this->accept(TokenType::ELIF)) {
    condition = this->statement();
    conditions.push_back(this->unwrap(condition));
    this->expect(TokenType::EOL);
    blocks.push_back(this->codeBlock());
  }
  if (this->accept(TokenType::ELSE)) {
    this->expect(TokenType::EOL);
    blocks.push_back(this->codeBlock());
  }
  auto endLoc = this->endLoc();
  this->expect(TokenType::ENDIF);
  return std::make_shared<SelectionStatement>(this->sourceFile, conditions,
                                              blocks, start, endLoc);
}

std::shared_ptr<Node>
Parser::foreachBlock(const std::pair<uint32_t, uint32_t> &start) {
  std::vector<std::shared_ptr<Node>> ids;
  if (idx >= this->tokens.size()) {
    return this->errorNode("Premature EOF");
  }
  auto curr = this->tokens[idx];
  auto startOfIdExpr = this->currLoc();
  auto end = this->endLoc();
  this->expect(TokenType::IDENTIFIER);
  if (curr.type == TokenType::IDENTIFIER) {
    ids.push_back(std::make_shared<IdExpression>(
        this->sourceFile, std::get<std::string>(curr.dat), startOfIdExpr, end));
  }
  if (this->accept(TokenType::COMMA)) {
    startOfIdExpr = this->currLoc();
    end = this->endLoc();
    if (idx >= this->tokens.size()) {
      return this->errorNode("Premature EOF");
    }
    curr = this->tokens[idx];
    this->expect(TokenType::IDENTIFIER);
    if (curr.type == TokenType::IDENTIFIER) {
      ids.push_back(std::make_shared<IdExpression>(
          this->sourceFile, std::get<std::string>(curr.dat), startOfIdExpr,
          end));
    }
  }
  this->expect(TokenType::COLON);
  auto items = this->statement();
  this->expect(TokenType::EOL);
  auto block = this->codeBlock();
  end = this->endLoc();
  this->expect(TokenType::ENDFOREACH);
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
    cond = this->accept(TokenType::EOL);
  }
  return ret;
}
