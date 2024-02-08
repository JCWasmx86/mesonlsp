#include "lexer.hpp"

#include <gtest/gtest.h>
#include <string>
#include <utility>

std::pair<std::vector<LexError>, std::vector<Token>>
lex(const std::string &input) {
  Lexer lexer(input);
  lexer.tokenize();
  return std::make_pair(lexer.errors, lexer.tokens);
}

TEST(LexerTest, testEmpty) {
  const auto &[errs, tokens] = lex("");
  ASSERT_EQ(0, errs.size());
  ASSERT_EQ(1, tokens.size());
  ASSERT_EQ(TokenType::TOKEOF, tokens[0].type);
}

TEST(LexerTest, testOnlyComment) {
  const auto &[errs, tokens] = lex("#foo");
  ASSERT_EQ(0, errs.size());
  ASSERT_EQ(1, tokens.size());
  ASSERT_EQ(TokenType::TOKEOF, tokens[0].type);
}

TEST(LexerTest, testCommentNewLine) {
  const auto &[errs, tokens] = lex("#foo\n#foo\r\n      \t");
  ASSERT_EQ(0, errs.size());
  ASSERT_EQ(3, tokens.size());
  ASSERT_EQ(TokenType::EOL, tokens[0].type);
  ASSERT_EQ(TokenType::EOL, tokens[1].type);
  ASSERT_EQ(TokenType::TOKEOF, tokens[2].type);
}

TEST(LexerTest, testString) {
  const auto &[errs, tokens] = lex("'foo'\n");
  ASSERT_EQ(0, errs.size());
  ASSERT_EQ(3, tokens.size());
  ASSERT_EQ(TokenType::STRING, tokens[0].type);
  ASSERT_EQ(std::get<StringData>(tokens[0].dat).str, "foo");
  ASSERT_EQ(TokenType::EOL, tokens[1].type);
  ASSERT_EQ(TokenType::TOKEOF, tokens[2].type);
}

TEST(LexerTest, testStringWithEscape) {
  const auto &[errs, tokens] = lex("'fo\\'o'\n");
  ASSERT_EQ(0, errs.size());
  ASSERT_EQ(3, tokens.size());
  ASSERT_EQ(TokenType::STRING, tokens[0].type);
  ASSERT_EQ(std::get<StringData>(tokens[0].dat).str, "fo\\'o");
  ASSERT_EQ(TokenType::EOL, tokens[1].type);
  ASSERT_EQ(TokenType::TOKEOF, tokens[2].type);
}

TEST(LexerTest, testFString) {
  const auto &[errs, tokens] = lex("f'foo'\n");
  ASSERT_EQ(0, errs.size());
  ASSERT_EQ(3, tokens.size());
  ASSERT_EQ(TokenType::STRING, tokens[0].type);
  ASSERT_EQ(std::get<StringData>(tokens[0].dat).str, "foo");
  ASSERT_TRUE(std::get<StringData>(tokens[0].dat).format);
  ASSERT_EQ(TokenType::EOL, tokens[1].type);
  ASSERT_EQ(TokenType::TOKEOF, tokens[2].type);
}

TEST(LexerTest, testMultilineString) {
  const auto &[errs, tokens] = lex("'''\nfoo\n'''\n");
  ASSERT_EQ(0, errs.size());
  ASSERT_EQ(3, tokens.size());
  ASSERT_EQ(TokenType::STRING, tokens[0].type);
  ASSERT_EQ(std::get<StringData>(tokens[0].dat).str, "\nfoo\n");
  ASSERT_TRUE(std::get<StringData>(tokens[0].dat).multiline);
  ASSERT_EQ(TokenType::EOL, tokens[1].type);
  ASSERT_EQ(TokenType::TOKEOF, tokens[2].type);
}

TEST(LexerTest, testIdentifier) {
  const auto &[errs, tokens] = lex("fooA_123a\n");
  ASSERT_EQ(3, tokens.size());
  ASSERT_EQ(0, errs.size());
  ASSERT_EQ(TokenType::IDENTIFIER, tokens[0].type);
  ASSERT_EQ(std::get<std::string>(tokens[0].dat), "fooA_123a");
  ASSERT_EQ(TokenType::EOL, tokens[1].type);
  ASSERT_EQ(TokenType::TOKEOF, tokens[2].type);
}

TEST(LexerTest, testKeyword) {
  const auto &[errs, tokens] =
      lex("and\nbreak\ncontinue\nelif\nelse\nendforeach\nendif\nfalse\nforeach"
          "\nif\nin\nnot\nor\ntrue\n");
  ASSERT_EQ(0, errs.size());
  ASSERT_EQ(29, tokens.size());
  ASSERT_EQ(TokenType::AND, tokens[0].type);
  ASSERT_EQ(TokenType::EOL, tokens[1].type);
  ASSERT_EQ(TokenType::BREAK, tokens[2].type);
  ASSERT_EQ(TokenType::EOL, tokens[3].type);
  ASSERT_EQ(TokenType::CONTINUE, tokens[4].type);
  ASSERT_EQ(TokenType::EOL, tokens[5].type);
  ASSERT_EQ(TokenType::ELIF, tokens[6].type);
  ASSERT_EQ(TokenType::EOL, tokens[7].type);
  ASSERT_EQ(TokenType::ELSE, tokens[8].type);
  ASSERT_EQ(TokenType::EOL, tokens[9].type);
  ASSERT_EQ(TokenType::ENDFOREACH, tokens[10].type);
  ASSERT_EQ(TokenType::EOL, tokens[11].type);
  ASSERT_EQ(TokenType::ENDIF, tokens[12].type);
  ASSERT_EQ(TokenType::EOL, tokens[13].type);
  ASSERT_EQ(TokenType::FALSE, tokens[14].type);
  ASSERT_EQ(TokenType::EOL, tokens[15].type);
  ASSERT_EQ(TokenType::FOREACH, tokens[16].type);
  ASSERT_EQ(TokenType::EOL, tokens[17].type);
  ASSERT_EQ(TokenType::IF, tokens[18].type);
  ASSERT_EQ(TokenType::EOL, tokens[19].type);
  ASSERT_EQ(TokenType::IN, tokens[20].type);
  ASSERT_EQ(TokenType::EOL, tokens[21].type);
  ASSERT_EQ(TokenType::NOT, tokens[22].type);
  ASSERT_EQ(TokenType::EOL, tokens[23].type);
  ASSERT_EQ(TokenType::OR, tokens[24].type);
  ASSERT_EQ(TokenType::EOL, tokens[25].type);
  ASSERT_EQ(TokenType::TRUE, tokens[26].type);
  ASSERT_EQ(TokenType::EOL, tokens[27].type);
  ASSERT_EQ(TokenType::TOKEOF, tokens[28].type);
}

TEST(LexerTest, testSpecialOps) {
  const auto &[errs, tokens] = lex("x + 1\nx += 2\n");
  ASSERT_EQ(9, tokens.size());
  ASSERT_EQ(0, errs.size());
  ASSERT_EQ(TokenType::PLUS, tokens[1].type);
  ASSERT_EQ(TokenType::PLUS_ASSIGN, tokens[5].type);
}

TEST(LexerTest, testSpecialOps2) {
  const auto &[errs, tokens] = lex("x = 1\nx == 2\n");
  ASSERT_EQ(9, tokens.size());
  ASSERT_EQ(0, errs.size());
  ASSERT_EQ(TokenType::ASSIGN, tokens[1].type);
  ASSERT_EQ(TokenType::EQ, tokens[5].type);
}

TEST(LexerTest, testNumbers) {
  const auto &[errs, tokens] = lex("0\n0b\n0b10\n0x10\n0o12\n100\n");
  ASSERT_EQ(13, tokens.size());
  ASSERT_EQ(1, errs.size());
  ASSERT_EQ(std::get<NumberData>(tokens[0].dat).asInt, 0);
  ASSERT_EQ(std::get<NumberData>(tokens[2].dat).asInt, 0b0);
  ASSERT_EQ(std::get<NumberData>(tokens[4].dat).asInt, 0b10);
  ASSERT_EQ(std::get<NumberData>(tokens[6].dat).asInt, 0x10);
  ASSERT_EQ(std::get<NumberData>(tokens[8].dat).asInt, 012);
  ASSERT_EQ(std::get<NumberData>(tokens[10].dat).asInt, 100);
}

int main(int argc, char **argv) {
  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
