#include "node.hpp"
#include "sourcefile.hpp"

#include <cstring>
#include <filesystem>
#include <gtest/gtest.h>
#include <ini.hpp>
#include <memory>
#include <tree_sitter/api.h>

extern "C" TSLanguage *tree_sitter_ini();   // NOLINT
extern "C" TSLanguage *tree_sitter_meson(); // NOLINT

std::shared_ptr<Node> parseToNode(std::string contents) {
  auto file = std::make_shared<MemorySourceFile>(
      contents, std::filesystem::path("test.ini"));
  TSParser *parser = ts_parser_new();
  ts_parser_set_language(parser, tree_sitter_meson());
  TSTree *tree = ts_parser_parse_string(parser, nullptr, contents.c_str(),
                                        contents.size());
  TSNode rootNode = ts_tree_root_node(tree);
  auto node = makeNode(file, rootNode);
  ts_tree_delete(tree);
  ts_parser_delete(parser);
  return node;
}

TEST(AstTestIni, testIniParsing) {
  const auto *const iniStr =
      "; Foo\n[foo]\nk=v\nk1=v\n[foo2]\n;comment\na=1\nb=1\nc=2\ncccccc=\n";
  auto file = std::make_shared<MemorySourceFile>(
      iniStr, std::filesystem::path("test.ini"));
  TSParser *parser = ts_parser_new();
  ts_parser_set_language(parser, tree_sitter_ini());
  TSTree *tree =
      ts_parser_parse_string(parser, nullptr, iniStr, strlen(iniStr));
  TSNode rootNode = ts_tree_root_node(tree);
  auto node = ast::ini::makeNode(file, rootNode);
  auto *iniFile = dynamic_cast<ast::ini::IniFile *>(node.get());
  ASSERT_NE(iniFile, nullptr);
  ASSERT_EQ(iniFile->sections.size(), 2);
  auto *section1 =
      dynamic_cast<ast::ini::Section *>(iniFile->sections[0].get());
  ASSERT_NE(section1, nullptr);
  auto *section1Name =
      dynamic_cast<ast::ini::StringValue *>(section1->name.get());
  ASSERT_NE(section1Name, nullptr);
  ASSERT_EQ(section1Name->value, "foo");
  ASSERT_EQ(section1->keyValuePairs.size(), 2);
  auto *section2 =
      dynamic_cast<ast::ini::Section *>(iniFile->sections[1].get());
  ASSERT_NE(section2, nullptr);
  ASSERT_EQ(section2->keyValuePairs.size(), 4);
  ts_tree_delete(tree);
  ts_parser_delete(parser);
}

TEST(TestAst, testEmpty) {
  auto node = parseToNode("");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 0);
}

TEST(TestAst, testBuildDefinition) {
  auto node = parseToNode("x = 1");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 1);
  ASSERT_NE(dynamic_cast<AssignmentStatement *>(bd->stmts[0].get()), nullptr);
}

TEST(TestAst, testBuildDefinitionComment) {
  auto node = parseToNode("#Foo\nx = 1");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 1);
  ASSERT_NE(dynamic_cast<AssignmentStatement *>(bd->stmts[0].get()), nullptr);
}

TEST(TestAst, testKeywordItem) {
  auto node = parseToNode("project('test', foo: #\n 1)");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 1);
  auto fe = dynamic_cast<FunctionExpression *>(bd->stmts[0].get());
  ASSERT_NE(fe, nullptr);
  auto al = dynamic_cast<ArgumentList *>(fe->args.get());
  ASSERT_NE(al, nullptr);
  ASSERT_EQ(al->args.size(), 2);
  ASSERT_NE(dynamic_cast<StringLiteral *>(al->args[0].get()), nullptr);
  auto *kwi = dynamic_cast<KeywordItem *>(al->args[1].get());
  ASSERT_NE(kwi, nullptr);
  ASSERT_TRUE(kwi->name.has_value());
  ASSERT_NE(dynamic_cast<IdExpression *>(kwi->key.get()), nullptr);
  ASSERT_NE(dynamic_cast<IntegerLiteral *>(kwi->value.get()), nullptr);
}

TEST(TestAst, testArgumentList) {
  auto node = parseToNode("project('test', foo: #\n 1, foo2: 1)");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 1);
  auto *fe = dynamic_cast<FunctionExpression *>(bd->stmts[0].get());
  ASSERT_NE(fe, nullptr);
  auto *al = dynamic_cast<ArgumentList *>(fe->args.get());
  ASSERT_NE(al, nullptr);
  ASSERT_EQ(al->args.size(), 3);
  auto arg = al->getPositionalArg(0);
  ASSERT_TRUE(arg.has_value());
  arg = al->getPositionalArg(1);
  ASSERT_FALSE(arg.has_value());
  arg = al->getPositionalArg(2);
  ASSERT_FALSE(arg.has_value());
  arg = al->getKwarg("foo");
  ASSERT_TRUE(arg.has_value());
  arg = al->getKwarg("f11oo");
  ASSERT_FALSE(arg.has_value());
}

TEST(TestAst, testArrayLiteral) {
  auto node = parseToNode("['foo',\n# foo,\n # bar,\n 123]");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 1);
  auto *arrayLit = dynamic_cast<ArrayLiteral *>(bd->stmts[0].get());
  ASSERT_NE(arrayLit, nullptr);
  ASSERT_EQ(arrayLit->args.size(), 2);
}

TEST(TestAst, testAssignmentStatement) {
  auto node = parseToNode("x = 5\ny *= 2\nz /= 3\na %= 2\nb += 2\nc -= 3");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 6);
  for (const auto &stmt : bd->stmts) {
    auto *ass = dynamic_cast<AssignmentStatement *>(stmt.get());
    ASSERT_NE(ass, nullptr);
    ASSERT_NE(dynamic_cast<IdExpression *>(ass->lhs.get()), nullptr);
    ASSERT_NE(dynamic_cast<IntegerLiteral *>(ass->rhs.get()), nullptr);
  }
  ASSERT_EQ(dynamic_cast<AssignmentStatement *>(bd->stmts[0].get())->op,
            AssignmentOperator::Equals);
  ASSERT_EQ(dynamic_cast<AssignmentStatement *>(bd->stmts[1].get())->op,
            AssignmentOperator::MulEquals);
  ASSERT_EQ(dynamic_cast<AssignmentStatement *>(bd->stmts[2].get())->op,
            AssignmentOperator::DivEquals);
  ASSERT_EQ(dynamic_cast<AssignmentStatement *>(bd->stmts[3].get())->op,
            AssignmentOperator::ModEquals);
  ASSERT_EQ(dynamic_cast<AssignmentStatement *>(bd->stmts[4].get())->op,
            AssignmentOperator::PlusEquals);
  ASSERT_EQ(dynamic_cast<AssignmentStatement *>(bd->stmts[5].get())->op,
            AssignmentOperator::MinusEquals);
}

TEST(TestAst, testBinaryExpressionArithmetic) {
  auto node = parseToNode("a + b\na - b\na * b\na / b\n");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 4);
  for (const auto &stmt : bd->stmts) {
    auto *ass = dynamic_cast<BinaryExpression *>(stmt.get());
    ASSERT_NE(ass, nullptr);
    ASSERT_NE(dynamic_cast<IdExpression *>(ass->lhs.get()), nullptr);
    ASSERT_NE(dynamic_cast<IdExpression *>(ass->rhs.get()), nullptr);
  }
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[0].get())->op,
            BinaryOperator::Plus);
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[1].get())->op,
            BinaryOperator::Minus);
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[2].get())->op,
            BinaryOperator::Mul);
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[3].get())->op,
            BinaryOperator::Div);
}

TEST(TestAst, testBinaryExpressionComparison) {
  auto node = parseToNode("a == b\na != b\na > b\na < b\na >= b\na <= b");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 6);
  for (const auto &stmt : bd->stmts) {
    auto *ass = dynamic_cast<BinaryExpression *>(stmt.get());
    ASSERT_NE(ass, nullptr);
    ASSERT_NE(dynamic_cast<IdExpression *>(ass->lhs.get()), nullptr);
    ASSERT_NE(dynamic_cast<IdExpression *>(ass->rhs.get()), nullptr);
  }
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[0].get())->op,
            BinaryOperator::EqualsEquals);
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[1].get())->op,
            BinaryOperator::NotEquals);
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[2].get())->op,
            BinaryOperator::Gt);
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[3].get())->op,
            BinaryOperator::Lt);
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[4].get())->op,
            BinaryOperator::Ge);
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[5].get())->op,
            BinaryOperator::Le);
}

TEST(TestAst, testBinaryExpressionOther) {
  auto node = parseToNode("a in b\na not in b\na or b\na and b\n");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 4);
  for (const auto &stmt : bd->stmts) {
    auto *ass = dynamic_cast<BinaryExpression *>(stmt.get());
    ASSERT_NE(ass, nullptr);
    ASSERT_NE(dynamic_cast<IdExpression *>(ass->lhs.get()), nullptr);
    ASSERT_NE(dynamic_cast<IdExpression *>(ass->rhs.get()), nullptr);
  }
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[0].get())->op,
            BinaryOperator::In);
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[1].get())->op,
            BinaryOperator::NotIn);
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[2].get())->op,
            BinaryOperator::Or);
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[3].get())->op,
            BinaryOperator::And);
}

TEST(TestAst, testBooleanLiteral) {
  auto node = parseToNode("x = true\ny = false\n");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 2);
  auto *ass = dynamic_cast<AssignmentStatement *>(bd->stmts[0].get());
  ASSERT_NE(ass, nullptr);
  auto *rhs = dynamic_cast<BooleanLiteral *>(ass->rhs.get());
  ASSERT_NE(rhs, nullptr);
  ASSERT_TRUE(rhs->value);
  ass = dynamic_cast<AssignmentStatement *>(bd->stmts[1].get());
  ASSERT_NE(ass, nullptr);
  rhs = dynamic_cast<BooleanLiteral *>(ass->rhs.get());
  ASSERT_NE(rhs, nullptr);
  ASSERT_FALSE(rhs->value);
}

int main(int argc, char **argv) {
  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
