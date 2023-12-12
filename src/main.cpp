#include "libast/sourcefile.hpp"
#include <cstddef>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <jsonrpc.hpp>
#include <memory>
#include <node.hpp>
#include <sourcefile.hpp>
#include <string>
#include <tree_sitter/api.h>
#include <vector>

extern "C" TSLanguage *tree_sitter_meson();

void printHelp() {
  std::cerr << "Usage: Swift-MesonLSP [<options>] [<paths> ...]" << std::endl
            << std::endl;
  std::cerr << "ARGUMENTS:" << std::endl;
  std::cerr << "  <paths>\tPath to parse" << std::endl << std::endl;
  std::cerr << "OPTIONS:" << std::endl;
  std::cerr
      << "--path <path>\tPath to parse 100x times (default: ./meson.build)"
      << std::endl;
  std::cerr << "--lsp        \tStart language server over stdio" << std::endl;
  std::cerr << "--version    \tPrint version" << std::endl;
  std::cerr << "--help       \tPrint this help" << std::endl;
}

void printVersion() { std::cout << VERSION << std::endl; }

void startLanguageServer() {}

int main(int argc, char **argv) {
  std::string path = "./meson.build";
  std::vector<std::string> paths;
  bool lsp = false;
  bool help = false;
  bool version = false;
  bool error = false;
  for (int i = 1; i < argc; i++) {
    if (strcmp("--lsp", argv[i]) == 0) {
      lsp = true;
      continue;
    }
    if (strcmp("--stdio", argv[i]) == 0) {
      continue;
    }
    if (strcmp("--help", argv[i]) == 0) {
      help = true;
      continue;
    }
    if (strcmp("--version", argv[i]) == 0) {
      version = true;
      continue;
    }
    if (strcmp("--path", argv[i]) == 0) {
      if (i + 1 == argc) {
        std::cerr << "Error: Missing value for --path <path>" << std::endl;
        error = true;
        break;
      }
      path = std::string(argv[i + 1]);
      i++;
      continue;
    }
    if (strncmp(argv[i], "--", 2) == 0) {
      std::cerr << "Unknown option: " << argv[i] << std::endl;
      error = true;
      continue;
    }
    paths.push_back(std::string(argv[i]));
  }
  if (error || help) {
    printHelp();
    return error ? EXIT_FAILURE : EXIT_SUCCESS;
  }
  if (version) {
    printVersion();
    return EXIT_SUCCESS;
  }
  if (lsp) {
    startLanguageServer();
    return EXIT_SUCCESS;
  }
  if (paths.size() == 0) {
    TSParser *parser = ts_parser_new();
    ts_parser_set_language(parser, tree_sitter_meson());
    auto fpath = std::filesystem::path(path);
    if (!std::filesystem::exists(fpath)) {
      std::cerr << fpath.c_str() << " does not exist!" << std::endl;
      return EXIT_SUCCESS;
    }
    if (!std::filesystem::is_regular_file(fpath)) {
      std::cerr << fpath.c_str() << " is not a file!" << std::endl;
      return EXIT_SUCCESS;
    }
    std::ifstream file(path);
    auto file_size = std::filesystem::file_size(fpath);
    std::string file_content;
    file_content.resize(file_size, '\0');
    file.read(file_content.data(), file_size);
    TSTree *tree = ts_parser_parse_string(parser, NULL, file_content.data(),
                                          file_content.length());
    TSNode root_node = ts_tree_root_node(tree);
    auto source_file = std::make_shared<SourceFile>(fpath);
    auto root = make_node(source_file, root_node);

    ts_tree_delete(tree);
    ts_parser_delete(parser);
    return 0;
  }
}
