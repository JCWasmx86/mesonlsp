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
#include <memory>
#include <string>
#include <tree_sitter/api.h>

extern "C" TSLanguage *tree_sitter_meson(); // NOLINT

static Logger LOG("analyze::mesontree"); // NOLINT

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
  if (this->overrides.contains(path)) {
    auto fileContent = this->overrides[path];
    TSTree *tree = ts_parser_parse_string(parser, nullptr, fileContent.data(),
                                          fileContent.length());
    auto sourceFile = std::make_shared<MemorySourceFile>(fileContent, path);
    const TSNode rootNode = ts_tree_root_node(tree);
    auto root = makeNode(sourceFile, rootNode);
    this->ownedFiles.insert(std::filesystem::absolute(path));
    root->setParents();
    if (!this->asts.contains(root->file->file)) {
      this->asts[root->file->file] = {};
    }
    this->asts[root->file->file].push_back(root);
    ts_tree_delete(tree);
    ts_parser_delete(parser);
    return this->asts[root->file->file].back();
  }
  auto fileContent = readFile(path);
  TSTree *tree = ts_parser_parse_string(parser, nullptr, fileContent.data(),
                                        fileContent.length());
  const TSNode rootNode = ts_tree_root_node(tree);
  auto sourceFile = std::make_shared<SourceFile>(path);
  auto root = makeNode(sourceFile, rootNode);
  if (!this->asts.contains(root->file->file)) {
    this->asts[root->file->file] = {};
  }
  this->ownedFiles.insert(std::filesystem::absolute(path));
  root->setParents();
  this->asts[root->file->file].push_back(root);
  ts_tree_delete(tree);
  ts_parser_delete(parser);
  return this->asts[root->file->file].back();
}

void MesonTree::partialParse(AnalysisOptions analysisOptions) {
  LOG.info(std::format("Parsing {} ({})", this->identifier,
                       this->root.generic_string()));
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
  this->scope = visitor.scope;
  this->options = visitor.options;
}
