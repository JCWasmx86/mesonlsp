#include "lexer.hpp"
#include "parser.hpp"
#include "sourcefile.hpp"
#include "utils.hpp"

#include <filesystem>
#include <format>
#include <iostream>
#include <string>

extern "C" {
// Dirty hack
#define ast muon_ast
#include <lang/lexer.h>
#include <lang/parser.h>
#include <log.h>
#include <platform/filesystem.h>
#include <platform/init.h>
#undef ast
}
extern "C" TSLanguage *tree_sitter_meson(); // NOLINT
constexpr auto COUNT = 0;

int main(int argc, char **argv) {
  std::string mode = argv[1];
  auto *file = argv[2];
  if (mode == "muon") {
    struct source src = {nullptr, nullptr, 0, source_reopen_type_none};
    fs_read_entire_file(file, &src);
    for (int i = 0; i < COUNT; i++) {
      struct muon_ast ast = {{0, 0, 0, nullptr}, {}, 0, 0};
      struct source_data sdata = {nullptr, 0};
      parser_parse(nullptr, &ast, &sdata, &src,
                   pm_ignore_statement_with_no_effect);
      ast_destroy(&ast);
      source_data_destroy(&sdata);
    }
  } else if (mode == "custom") {
    const auto fileContent = readFile(file);
    std::filesystem::path path = file;
    for (int i = 0; i < COUNT; i++) {
      Lexer lexer(fileContent);
      lexer.tokenize();
      auto sourceFile = std::make_shared<MemorySourceFile>(fileContent, path);
      Parser parser(lexer.tokens, sourceFile);
      auto rootNode = parser.parse();
      rootNode->setParents();
    }
    if (argc == 4 && strcmp(argv[3], "--print") == 0) {
      Lexer lexer(fileContent);
      lexer.tokenize();
      auto sourceFile = std::make_shared<MemorySourceFile>(fileContent, path);
      Parser parser(lexer.tokens, sourceFile);
      auto rootNode = parser.parse();
      rootNode->setParents();
      std::cerr << rootNode->toString() << std::endl;
      for (const auto &err : lexer.errors) {
        std::cerr << std::format("[{}:{}] {}", err.line, err.column,
                                 err.message)
                  << std::endl;
      }
      for (const auto &err : parser.errors) {
        std::cerr << std::format("[{}:{}] {}", err.line, err.column,
                                 err.message)
                  << std::endl;
      }
    }
  } else if (mode == "tree-sitter") {
    const auto fileContent = readFile(file);
    std::filesystem::path path = file;
    TSParser *parser = ts_parser_new();
    ts_parser_set_language(parser, tree_sitter_meson());
    for (int i = 0; i < COUNT; i++) {
      TSTree *tree = ts_parser_parse_string(parser, nullptr, fileContent.data(),
                                            (uint32_t)fileContent.length());
      auto sourceFile = std::make_shared<MemorySourceFile>(fileContent, path);
      auto rootNode = makeNode(sourceFile, ts_tree_root_node(tree));
      rootNode->setParents();
      ts_tree_delete(tree);
    }
    ts_parser_delete(parser);
  }
}
