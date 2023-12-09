#include <cassert>
#include <cstring>
#include <ini.hpp>
#include <memory>

extern "C" TSLanguage *tree_sitter_ini();
int main(int argc, char **argv) {
  const auto ini_str =
      "; Foo\n[foo]\nk=v\nk1=v\n[foo2]\na=1\nb=1\nc=2\ncccccc=\n";
  auto file = std::make_shared<MemorySourceFile>(
      ini_str, std::filesystem::path("test.ini"));
  TSParser *parser = ts_parser_new();
  ts_parser_set_language(parser, tree_sitter_ini());
  TSTree *tree = ts_parser_parse_string(parser, NULL, ini_str, strlen(ini_str));
  TSNode root_node = ts_tree_root_node(tree);
  auto node = ast::ini::make_node(file, root_node);
  auto ini_file = dynamic_cast<ast::ini::IniFile *>(node.get());
  assert(ini_file);
  assert(ini_file->sections.size() == 2);
  auto section1 =
      dynamic_cast<ast::ini::Section *>(ini_file->sections[0].get());
  assert(section1);
  auto section1_name =
      dynamic_cast<ast::ini::StringValue *>(section1->name.get());
  assert(section1_name);
  assert(section1_name->value == "foo");
  assert(section1->key_value_pairs.size() == 2);
  auto section2 =
      dynamic_cast<ast::ini::Section *>(ini_file->sections[1].get());
  assert(section2);
  assert(section2->key_value_pairs.size() == 4);
  ts_tree_delete(tree);
  ts_parser_delete(parser);
}
