#include "sourcefile.hpp"

#include <cstring>
#include <filesystem>
#include <gtest/gtest.h>
#include <ini.hpp>
#include <memory>
#include <tree_sitter/api.h>

extern "C" TSLanguage *tree_sitter_ini(); // NOLINT

TEST(AstTestIni, testIniParsing) {
  const auto *const iniStr =
      "; Foo\n[foo]\nk=v\nk1=v\n[foo2]\na=1\nb=1\nc=2\ncccccc=\n";
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

int main(int argc, char **argv) {
  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
