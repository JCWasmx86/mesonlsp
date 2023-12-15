#include "sourcefile.hpp"
#include <cassert>
#include <cstring>
#include <filesystem>
#include <ini.hpp>
#include <memory>
#include <tree_sitter/api.h>

extern "C" TSLanguage *tree_sitter_ini(); // NOLINT
int main(int argc, char **argv) {
  const auto iniStr =
      "; Foo\n[foo]\nk=v\nk1=v\n[foo2]\na=1\nb=1\nc=2\ncccccc=\n";
  auto file = std::make_shared<MemorySourceFile>(
      iniStr, std::filesystem::path("test.ini"));
  TSParser *parser = ts_parser_new();
  ts_parser_set_language(parser, tree_sitter_ini());
  TSTree *tree = ts_parser_parse_string(parser, NULL, iniStr, strlen(iniStr));
  TSNode rootNode = ts_tree_root_node(tree);
  auto node = ast::ini::makeNode(file, rootNode);
  auto iniFile = dynamic_cast<ast::ini::IniFile *>(node.get());
  assert(iniFile);
  assert(iniFile->sections.size() == 2);
  auto section1 = dynamic_cast<ast::ini::Section *>(iniFile->sections[0].get());
  assert(section1);
  auto section1Name =
      dynamic_cast<ast::ini::StringValue *>(section1->name.get());
  assert(section1Name);
  assert(section1Name->value == "foo");
  assert(section1->key_value_pairs.size() == 2);
  auto section2 = dynamic_cast<ast::ini::Section *>(iniFile->sections[1].get());
  assert(section2);
  assert(section2->key_value_pairs.size() == 4);
  ts_tree_delete(tree);
  ts_parser_delete(parser);
}
