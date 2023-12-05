#include "libast/sourcefile.hpp"
#include <cstddef>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <memory>
#include <node.hpp>
#include <sourcefile.hpp>
#include <tree_sitter/api.h>

extern "C" TSLanguage *tree_sitter_meson();
int main(int argc, char **argv) {
  TSParser *parser = ts_parser_new();
  ts_parser_set_language(parser, tree_sitter_meson());
  auto path = std::filesystem::path(argv[1]);
  std::ifstream file(path);
  auto file_size = std::filesystem::file_size(path);
  std::string file_content;
  file_content.resize(file_size, '\0');
  file.read(file_content.data(), file_size);
  TSTree *tree = ts_parser_parse_string(parser, NULL, file_content.data(),
                                        file_content.length());
  TSNode root_node = ts_tree_root_node(tree);
  auto source_file = std::make_shared<MesonSourceFile>(path);
  auto root = make_node(source_file, root_node);

  ts_tree_delete(tree);
  ts_parser_delete(parser);
}