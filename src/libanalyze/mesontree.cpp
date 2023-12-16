#include "mesontree.hpp"
#include "log.hpp"
#include "optionextractor.hpp"
#include "optionstate.hpp"
#include <filesystem>
#include <fstream>
#include <tree_sitter/api.h>

extern "C" TSLanguage *tree_sitter_meson(); // NOLINT

static Logger LOG("analyze::mesontree"); // NOLINT

void MesonTree::fastParse(AnalysisOptions analysisOptions) {
  OptionState optionState;
  auto modernOptionsFile = this->root / "meson.options";
  LOG.info(modernOptionsFile.generic_string());
  // First parse the meson_options.txt/meson.options file
  auto visitor = OptionExtractor();
  if (std::filesystem::exists(modernOptionsFile) &&
      std::filesystem::is_regular_file(modernOptionsFile)) {
    TSParser *parser = ts_parser_new();
    ts_parser_set_language(parser, tree_sitter_meson());
    std::ifstream file(modernOptionsFile.c_str());
    auto fileSize = std::filesystem::file_size(modernOptionsFile);
    std::string fileContent;
    fileContent.resize(fileSize, '\0');
    file.read(fileContent.data(), fileSize);
    TSTree *tree = ts_parser_parse_string(parser, NULL, fileContent.data(),
                                          fileContent.length());
    TSNode rootNode = ts_tree_root_node(tree);
    auto sourceFile = std::make_shared<SourceFile>(modernOptionsFile);
    auto root = makeNode(sourceFile, rootNode);
    root->visit(&visitor);
    optionState = OptionState(visitor.options);
    ts_tree_delete(tree);
    ts_parser_delete(parser);
  } else {
    auto legacyOptionsFile = this->root / "meson_options.txt";
    if (std::filesystem::exists(legacyOptionsFile) &&
        std::filesystem::is_regular_file(legacyOptionsFile)) {
      TSParser *parser = ts_parser_new();
      ts_parser_set_language(parser, tree_sitter_meson());
      std::ifstream file(legacyOptionsFile.c_str());
      auto fileSize = std::filesystem::file_size(legacyOptionsFile);
      std::string fileContent;
      fileContent.resize(fileSize, '\0');
      file.read(fileContent.data(), fileSize);
      TSTree *tree = ts_parser_parse_string(parser, NULL, fileContent.data(),
                                            fileContent.length());
      TSNode rootNode = ts_tree_root_node(tree);
      auto sourceFile = std::make_shared<SourceFile>(legacyOptionsFile);
      auto root = makeNode(sourceFile, rootNode);
      root->visit(&visitor);
      optionState = OptionState(visitor.options);
      ts_tree_delete(tree);
      ts_parser_delete(parser);
    }
  }
  // Then parse the root meson.build file
}
