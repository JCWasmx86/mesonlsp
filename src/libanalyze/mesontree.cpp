#include "mesontree.hpp"

#include "analysisoptions.hpp"
#include "log.hpp"
#include "node.hpp"
#include "optionextractor.hpp"
#include "optionstate.hpp"
#include "scope.hpp"
#include "sourcefile.hpp"
#include "typeanalyzer.hpp"

#include <filesystem>
#include <format>
#include <fstream>
#include <ios>
#include <memory>
#include <string>
#include <tree_sitter/api.h>

extern "C" TSLanguage *tree_sitter_meson(); // NOLINT

static Logger LOG("analyze::mesontree"); // NOLINT

std::string readFile(std::filesystem::path &path) {
  std::ifstream file(path.c_str());
  auto fileSize = std::filesystem::file_size(path);
  std::string fileContent;
  fileContent.resize(fileSize, '\0');
  file.read(fileContent.data(), (std::streamsize)fileSize);
  return fileContent;
}

OptionState parseFile(std::filesystem::path path) {
  auto visitor = OptionExtractor();
  TSParser *parser = ts_parser_new();
  ts_parser_set_language(parser, tree_sitter_meson());
  auto fileContent = readFile(path);
  TSTree *tree = ts_parser_parse_string(parser, nullptr, fileContent.data(),
                                        fileContent.length());
  const TSNode rootNode = ts_tree_root_node(tree);
  auto sourceFile = std::make_shared<SourceFile>(path);
  auto root = makeNode(sourceFile, rootNode);
  root->visit(&visitor);
  auto optionState = OptionState(visitor.options);
  ts_tree_delete(tree);
  ts_parser_delete(parser);
  return optionState;
}

OptionState parseOptions(std::filesystem::path &root) {
  auto modernOptionsFile = root / "meson.options";
  if (std::filesystem::exists(modernOptionsFile) &&
      std::filesystem::is_regular_file(modernOptionsFile)) {
    return parseFile(modernOptionsFile);
  }
  auto legacyOptionsFile = root / "meson_options.txt";
  if (std::filesystem::exists(legacyOptionsFile) &&
      std::filesystem::is_regular_file(legacyOptionsFile)) {
    return parseFile(legacyOptionsFile);
  }
  return {};
}

std::shared_ptr<Node> MesonTree::parseFile(std::filesystem::path path) {
  TSParser *parser = ts_parser_new();
  ts_parser_set_language(parser, tree_sitter_meson());
  auto fileContent = readFile(path);
  TSTree *tree = ts_parser_parse_string(parser, nullptr, fileContent.data(),
                                        fileContent.length());
  const TSNode rootNode = ts_tree_root_node(tree);
  auto sourceFile = std::make_shared<SourceFile>(path);
  auto root = makeNode(sourceFile, rootNode);
  this->ownedFiles.insert(std::filesystem::absolute(path));
  root->setParents();
  ts_tree_delete(tree);
  ts_parser_delete(parser);
  return root;
}

void MesonTree::partialParse(AnalysisOptions analysisOptions) {
  LOG.info(std::format("Parsing {}", this->identifier));
  // First fetch all the options
  auto options = parseOptions(this->root);
  // Then fetch diagnostics for the options
  // Then parse the root meson.build file
  auto rootFile = this->root / "meson.build";
  if (!std::filesystem::exists(rootFile)) {
    LOG.warn(std::format("No meson.build file in {}", this->root.c_str()));
    return;
  }
  auto root = this->parseFile(rootFile);
  Scope scope;
  scope.variables["meson"] = {this->ns.types.at("meson")};
  scope.variables["build_machine"] = {this->ns.types.at("build_machine")};
  scope.variables["host_machine"] = {this->ns.types.at("host_machine")};
  scope.variables["target_machine"] = {this->ns.types.at("target_machine")};
  TypeAnalyzer visitor(this->ns, &this->metadata, this, scope, analysisOptions,
                       options);
  root->setParents();
  root->visit(&visitor);
}
