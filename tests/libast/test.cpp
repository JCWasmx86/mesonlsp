#include "node.hpp"
#include "sourcefile.hpp"

#include <cstdint>
#include <cstring>
#include <filesystem>
#include <gtest/gtest.h>
#include <ini.hpp>
#include <memory>
#include <set>
#include <string>
#include <tree_sitter/api.h>
#include <vector>

extern "C" TSLanguage *tree_sitter_ini();   // NOLINT
extern "C" TSLanguage *tree_sitter_meson(); // NOLINT

std::shared_ptr<Node> parseToNode(const std::string &contents) {
  auto file = std::make_shared<MemorySourceFile>(
      contents, std::filesystem::path("test.ini"));
  TSParser *parser = ts_parser_new();
  ts_parser_set_language(parser, tree_sitter_meson());
  TSTree *tree = ts_parser_parse_string(parser, nullptr, contents.c_str(),
                                        contents.size());
  TSNode const rootNode = ts_tree_root_node(tree);
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
  TSNode const rootNode = ts_tree_root_node(tree);
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

TEST(TestAst, testExtractNodeValueSingleLine) {
  auto node = parseToNode("project('foo')");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 1);
  auto *fe = dynamic_cast<FunctionExpression *>(bd->stmts[0].get());
  ASSERT_NE(fe, nullptr);
  auto str = fe->file->extractNodeValue(fe->id->location);
  ASSERT_EQ(str, "project");
  auto *const sl = dynamic_cast<StringLiteral *>(
      dynamic_cast<ArgumentList *>(fe->args.get())->args[0].get());
  str = fe->file->extractNodeValue(sl->location);
  ASSERT_EQ(str, "'foo'");
}

TEST(TestAst, testExtractNodeValueMultiLine) {
  auto node = parseToNode("xyz = [\n  1,\n]\n");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 1);
  auto *asS = dynamic_cast<AssignmentStatement *>(bd->stmts[0].get());
  auto str = asS->file->extractNodeValue(asS->rhs->location);
  ASSERT_EQ(str, "[\n  1,\n]");
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
  auto *fe = dynamic_cast<FunctionExpression *>(bd->stmts[0].get());
  ASSERT_NE(fe, nullptr);
  auto *al = dynamic_cast<ArgumentList *>(fe->args.get());
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

TEST(TestAst, testJumpStatement) {
  auto node = parseToNode("break\ncontinue\n");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 2);
  ASSERT_NE(dynamic_cast<BreakNode *>(bd->stmts[0].get()), nullptr);
  ASSERT_NE(dynamic_cast<ContinueNode *>(bd->stmts[1].get()), nullptr);
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
            AssignmentOperator::EQUALS);
  ASSERT_EQ(dynamic_cast<AssignmentStatement *>(bd->stmts[1].get())->op,
            AssignmentOperator::MUL_EQUALS);
  ASSERT_EQ(dynamic_cast<AssignmentStatement *>(bd->stmts[2].get())->op,
            AssignmentOperator::DIV_EQUALS);
  ASSERT_EQ(dynamic_cast<AssignmentStatement *>(bd->stmts[3].get())->op,
            AssignmentOperator::MOD_EQUALS);
  ASSERT_EQ(dynamic_cast<AssignmentStatement *>(bd->stmts[4].get())->op,
            AssignmentOperator::PLUS_EQUALS);
  ASSERT_EQ(dynamic_cast<AssignmentStatement *>(bd->stmts[5].get())->op,
            AssignmentOperator::MINUS_EQUALS);
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
            BinaryOperator::PLUS);
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[1].get())->op,
            BinaryOperator::MINUS);
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[2].get())->op,
            BinaryOperator::MUL);
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[3].get())->op,
            BinaryOperator::DIV);
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
            BinaryOperator::EQUALS_EQUALS);
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[1].get())->op,
            BinaryOperator::NOT_EQUALS);
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[2].get())->op,
            BinaryOperator::GT);
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[3].get())->op,
            BinaryOperator::LT);
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[4].get())->op,
            BinaryOperator::GE);
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[5].get())->op,
            BinaryOperator::LE);
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
            BinaryOperator::IN);
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[1].get())->op,
            BinaryOperator::NOT_IN);
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[2].get())->op,
            BinaryOperator::OR);
  ASSERT_EQ(dynamic_cast<BinaryExpression *>(bd->stmts[3].get())->op,
            BinaryOperator::AND);
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

TEST(TestAst, testConditionalExpression) {
  auto node = parseToNode("true ? x : y\n");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 1);
  auto *ce = dynamic_cast<ConditionalExpression *>(bd->stmts[0].get());
  ASSERT_NE(ce, nullptr);
  ASSERT_FALSE(ce->ifTrue->equals(ce->ifFalse.get()));
  ASSERT_FALSE(ce->ifTrue->equals(ce->condition.get()));
  ASSERT_FALSE(ce->condition->equals(ce->ifFalse.get()));
}

TEST(TestAst, testDictionaryLiteral) {
  auto node = parseToNode("{'foo': 1,\n# 'bar': 2,\n 'baz': 3\n}\n");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 1);
  auto *dictLit = dynamic_cast<DictionaryLiteral *>(bd->stmts[0].get());
  ASSERT_NE(dictLit, nullptr);
  ASSERT_EQ(dictLit->values.size(), 2);
}

TEST(TestAst, testIdExpression) {
  auto node = parseToNode("x = 1\nxy = 2\nxyz = 3\n");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 3);
  ASSERT_EQ(
      dynamic_cast<IdExpression *>(
          dynamic_cast<AssignmentStatement *>(bd->stmts[0].get())->lhs.get())
          ->id,
      "x");
  ASSERT_EQ(
      dynamic_cast<IdExpression *>(
          dynamic_cast<AssignmentStatement *>(bd->stmts[1].get())->lhs.get())
          ->id,
      "xy");
  ASSERT_EQ(
      dynamic_cast<IdExpression *>(
          dynamic_cast<AssignmentStatement *>(bd->stmts[2].get())->lhs.get())
          ->id,
      "xyz");
}

TEST(TestAst, testFunctionExpression) {
  auto node = parseToNode("project()\nfoo(1,2)\n");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 2);
  auto *fe = dynamic_cast<FunctionExpression *>(bd->stmts[0].get());
  ASSERT_NE(fe, nullptr);
  ASSERT_EQ(fe->functionName(), "project");
  ASSERT_EQ(fe->args, nullptr);
  fe = dynamic_cast<FunctionExpression *>(bd->stmts[1].get());
  ASSERT_NE(fe, nullptr);
  ASSERT_EQ(fe->functionName(), "foo");
  ASSERT_NE(fe->args, nullptr);
}

TEST(TestAst, testIntegerLiteral) {
  auto node = parseToNode(
      "x = 123\nx = 0x11\nx = 0X11\nx = 0b11\nx = 0B11\nx = 0o755\nx = 0O755");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 7);
  std::vector<int> values = {123, 0x11, 0x11, 0b11, 0b11, 0755, 0755}; // NOLINT
  for (size_t i = 0; i < bd->stmts.size(); i++) {
    auto *ass = dynamic_cast<AssignmentStatement *>(bd->stmts[i].get());
    ASSERT_NE(ass, nullptr);
    auto *rhs = dynamic_cast<IntegerLiteral *>(ass->rhs.get());
    ASSERT_NE(rhs, nullptr);
    ASSERT_EQ(rhs->valueAsInt, values[i]);
  }
}

TEST(TestAst, testIterationStatementEmpty) {
  auto node = parseToNode("foreach x, y : []\n\nendforeach");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 1);
  auto *its = dynamic_cast<IterationStatement *>(bd->stmts[0].get());
  ASSERT_NE(its, nullptr);
  ASSERT_EQ(its->ids.size(), 2);
  ASSERT_EQ(its->stmts.size(), 0);
}

TEST(TestAst, testIterationStatementComment) {
  auto node = parseToNode("foreach x, #foo\n y : []\n# foo\n\nendforeach");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 1);
  auto *its = dynamic_cast<IterationStatement *>(bd->stmts[0].get());
  ASSERT_NE(its, nullptr);
  ASSERT_EQ(its->ids.size(), 2);
  ASSERT_EQ(its->stmts.size(), 0);
}

TEST(TestAst, testIterationStatement) {
  auto node =
      parseToNode("foreach x, #foo\n y : []\n# foo\nbar()\n\nendforeach");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 1);
  auto *its = dynamic_cast<IterationStatement *>(bd->stmts[0].get());
  ASSERT_NE(its, nullptr);
  ASSERT_EQ(its->ids.size(), 2);
  ASSERT_EQ(its->stmts.size(), 1);
}

TEST(TestAst, testNormalStringLiteral) {
  auto node = parseToNode("x = 'foo'");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 1);
  auto *ass = dynamic_cast<AssignmentStatement *>(bd->stmts[0].get());
  ASSERT_NE(ass, nullptr);
  auto *sl = dynamic_cast<StringLiteral *>(ass->rhs.get());
  ASSERT_FALSE(sl->isFormat);
  ASSERT_EQ(sl->id, "foo");
}

TEST(TestAst, testMLStringLiteral) {
  auto node = parseToNode("x = '''\nfoo\n'''");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 1);
  auto *ass = dynamic_cast<AssignmentStatement *>(bd->stmts[0].get());
  ASSERT_NE(ass, nullptr);
  auto *sl = dynamic_cast<StringLiteral *>(ass->rhs.get());
  ASSERT_FALSE(sl->isFormat);
  ASSERT_EQ(sl->id, "\nfoo\n");
}

TEST(TestAst, testNormalFStringLiteral) {
  auto node = parseToNode("x = f'foo'");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 1);
  auto *ass = dynamic_cast<AssignmentStatement *>(bd->stmts[0].get());
  ASSERT_NE(ass, nullptr);
  auto *sl = dynamic_cast<StringLiteral *>(ass->rhs.get());
  ASSERT_TRUE(sl->isFormat);
  ASSERT_EQ(sl->id, "foo");
}

TEST(TestAst, testMLFStringLiteral) {
  auto node = parseToNode("x = f'''\nfoo\n'''");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 1);
  auto *ass = dynamic_cast<AssignmentStatement *>(bd->stmts[0].get());
  ASSERT_NE(ass, nullptr);
  auto *sl = dynamic_cast<StringLiteral *>(ass->rhs.get());
  ASSERT_TRUE(sl->isFormat);
  ASSERT_EQ(sl->id, "\nfoo\n");
}

TEST(TestAst, testMethodExpression) {
  auto node = parseToNode("x.foo()\nxyz.foo(1,2,3)\n");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 2);
  auto *me = dynamic_cast<MethodExpression *>(bd->stmts[0].get());
  ASSERT_NE(me, nullptr);
  ASSERT_EQ(me->args, nullptr);
  ASSERT_FALSE(me->obj->equals(me->id.get()));
  me = dynamic_cast<MethodExpression *>(bd->stmts[1].get());
  ASSERT_NE(me, nullptr);
  ASSERT_NE(me->args, nullptr);
  ASSERT_FALSE(me->obj->equals(me->id.get()));
  ASSERT_FALSE(me->id->equals(me->args.get()));
  ASSERT_FALSE(me->obj->equals(me->args.get()));
}

TEST(TestAst, testSelectionStatementIf) {
  auto node = parseToNode("if true\nfoo()\nendif");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 1);
  auto *sst = dynamic_cast<SelectionStatement *>(bd->stmts[0].get());
  ASSERT_NE(sst, nullptr);
  ASSERT_EQ(sst->conditions.size(), 1);
  ASSERT_EQ(sst->blocks.size(), 1);
  ASSERT_EQ(sst->blocks[0].size(), 1);
}

TEST(TestAst, testSelectionStatementEmpty) {
  auto node = parseToNode("if true\nendif");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 1);
  auto *sst = dynamic_cast<SelectionStatement *>(bd->stmts[0].get());
  ASSERT_NE(sst, nullptr);
  ASSERT_EQ(sst->conditions.size(), 1);
  ASSERT_EQ(sst->blocks.size(), 1);
  ASSERT_EQ(sst->blocks[0].size(), 0);
}

TEST(TestAst, testSelectionStatementComment) {
  auto node = parseToNode("if true\n#foo\nendif");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 1);
  auto *sst = dynamic_cast<SelectionStatement *>(bd->stmts[0].get());
  ASSERT_NE(sst, nullptr);
  ASSERT_EQ(sst->conditions.size(), 1);
  ASSERT_EQ(sst->blocks.size(), 1);
  ASSERT_EQ(sst->blocks[0].size(), 0);
}

TEST(TestAst, testSelectionStatementIf2) {
  auto node = parseToNode("if true\n#foo\nfoo()\nendif");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 1);
  auto *sst = dynamic_cast<SelectionStatement *>(bd->stmts[0].get());
  ASSERT_NE(sst, nullptr);
  ASSERT_EQ(sst->conditions.size(), 1);
  ASSERT_EQ(sst->blocks.size(), 1);
  ASSERT_EQ(sst->blocks[0].size(), 1);
}

TEST(TestAst, testSelectionStatementIfElse) {
  auto node = parseToNode("if true\nelse\nendif\n");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 1);
  auto *sst = dynamic_cast<SelectionStatement *>(bd->stmts[0].get());
  ASSERT_NE(sst, nullptr);
  ASSERT_EQ(sst->conditions.size(), 1);
  ASSERT_EQ(sst->blocks.size(), 2);
  ASSERT_EQ(sst->blocks[0].size(), 0);
  ASSERT_EQ(sst->blocks[1].size(), 0);
}

TEST(TestAst, testSelectionStatementIfElse2) {
  auto node = parseToNode("if true\nfoo()\nelse\n#Foo\nbar()\nendif\n");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 1);
  auto *sst = dynamic_cast<SelectionStatement *>(bd->stmts[0].get());
  ASSERT_NE(sst, nullptr);
  ASSERT_EQ(sst->conditions.size(), 1);
  ASSERT_EQ(sst->blocks.size(), 2);
  ASSERT_EQ(sst->blocks[0].size(), 1);
  ASSERT_EQ(sst->blocks[1].size(), 1);
}

TEST(TestAst, testSelectionStatementIfIfElse) {
  auto node = parseToNode("if true\nfoo()\nbar()\nelif 1 == "
                          "1\nfoo()\nelse\n#Foo\nbar()\nx = 1\ny = 1\nendif\n");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 1);
  auto *sst = dynamic_cast<SelectionStatement *>(bd->stmts[0].get());
  ASSERT_NE(sst, nullptr);
  ASSERT_EQ(sst->conditions.size(), 2);
  ASSERT_EQ(sst->blocks.size(), 3);
  ASSERT_EQ(sst->blocks[0].size(), 2);
  ASSERT_EQ(sst->blocks[1].size(), 1);
  ASSERT_EQ(sst->blocks[2].size(), 3);
}

TEST(TestAst, testSubscriptExpression) {
  auto node = parseToNode("foo[123]");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 1);
  auto *sse = dynamic_cast<SubscriptExpression *>(bd->stmts[0].get());
  ASSERT_NE(sse, nullptr);
  ASSERT_NE(dynamic_cast<IntegerLiteral *>(sse->inner.get()), nullptr);
  ASSERT_NE(dynamic_cast<IdExpression *>(sse->outer.get()), nullptr);
}

TEST(TestAst, testUnaryOperator) {
  auto node = parseToNode("x = not a\ny = !b\nz = -5\n");
  auto *bd = dynamic_cast<BuildDefinition *>(node.get());
  ASSERT_NE(bd, nullptr);
  ASSERT_EQ(bd->stmts.size(), 3);
  for (const auto &stmt : bd->stmts) {
    auto *ass = dynamic_cast<AssignmentStatement *>(stmt.get());
    ASSERT_NE(ass, nullptr);
    auto *unaryExpr = dynamic_cast<UnaryExpression *>(ass->rhs.get());
    ASSERT_NE(unaryExpr, nullptr);
  }
  ASSERT_EQ(
      dynamic_cast<UnaryExpression *>(
          dynamic_cast<AssignmentStatement *>(bd->stmts[0].get())->rhs.get())
          ->op,
      UnaryOperator::NOT);
  ASSERT_EQ(
      dynamic_cast<UnaryExpression *>(
          dynamic_cast<AssignmentStatement *>(bd->stmts[1].get())->rhs.get())
          ->op,
      UnaryOperator::EXCLAMATION_MARK);
  ASSERT_EQ(
      dynamic_cast<UnaryExpression *>(
          dynamic_cast<AssignmentStatement *>(bd->stmts[2].get())->rhs.get())
          ->op,
      UnaryOperator::UNARY_MINUS);
}

TEST(TestAstOther, extractTextBetweenAtSymbols) {
  auto inputs = extractTextBetweenAtSymbols("foo @0@ @e@ @ee@ @eee@ @eee0@");
  std::vector<std::string> const expected{"e", "ee", "eee", "eee0"};
  ASSERT_EQ(inputs, expected);
}

TEST(TestAstOther, dontExtractBetweenNumbers) {
  auto inputs = extractTextBetweenAtSymbols("@0@_@1@");
  ASSERT_TRUE(inputs.empty());
}

TEST(TestAstOther, extractIntegersBetweenAtSymbols) {
  auto inputs = extractIntegersBetweenAtSymbols("@0@ foo @011a@ @11@ @12@@13@");
  std::set<uint64_t> const expected{0, 11, 12, 13};
  ASSERT_EQ(inputs, expected);
}

TEST(TestAstOther, dontExtractBetweenStrings) {
  auto inputs = extractIntegersBetweenAtSymbols("@foo@0@bar@");
  // TODO: ASSERT_TRUE(inputs.empty());
}

int main(int argc, char **argv) {
  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
