#include "mesontree.hpp"

#include "analysisoptions.hpp"
#include "log.hpp"
#include "mesonmetadata.hpp"
#include "node.hpp"
#include "optiondiagnosticvisitor.hpp"
#include "optionextractor.hpp"
#include "optionstate.hpp"
#include "scope.hpp"
#include "sourcefile.hpp"
#include "typeanalyzer.hpp"
#include "utils.hpp"

#include <cstdint>
#include <filesystem>
#include <format>
#include <memory>
#include <string>
#include <tree_sitter/api.h>

extern "C" TSLanguage *tree_sitter_meson(); // NOLINT

const static Logger LOG("analyze::mesontree"); // NOLINT

OptionState MesonTree::parseFile(const std::filesystem::path &path,
                                 MesonMetadata *originalMetadata) {
  auto visitor = OptionExtractor();
  auto diagnosticVisitor = OptionDiagnosticVisitor(originalMetadata);
  TSParser *parser = ts_parser_new();
  ts_parser_set_language(parser, tree_sitter_meson());
  const auto &fileContent =
      this->overrides.contains(path) ? this->overrides[path] : readFile(path);
  TSTree *tree = ts_parser_parse_string(parser, nullptr, fileContent.data(),
                                        (uint32_t)fileContent.length());
  auto sourceFile = this->overrides.contains(path)
                        ? std::make_shared<MemorySourceFile>(fileContent, path)
                        : std::make_shared<SourceFile>(path);
  auto rootNode = makeNode(sourceFile, ts_tree_root_node(tree));
  rootNode->setParents();
  rootNode->visit(&visitor);
  rootNode->visit(&diagnosticVisitor);
  ts_tree_delete(tree);
  ts_parser_delete(parser);
  return OptionState{visitor.options};
}

OptionState MesonTree::parseOptions(const std::filesystem::path &treeRoot,
                                    MesonMetadata *originalMetadata) {
  const auto &modernOptionsFile = treeRoot / "meson.options";
  if (std::filesystem::exists(modernOptionsFile) &&
      std::filesystem::is_regular_file(modernOptionsFile)) {
    this->ownedFiles.insert(modernOptionsFile);
    return this->parseFile(modernOptionsFile, originalMetadata);
  }
  const auto &legacyOptionsFile = treeRoot / "meson_options.txt";
  if (std::filesystem::exists(legacyOptionsFile) &&
      std::filesystem::is_regular_file(legacyOptionsFile)) {
    this->ownedFiles.insert(legacyOptionsFile);
    return this->parseFile(legacyOptionsFile, originalMetadata);
  }
  return {};
}

std::shared_ptr<Node> MesonTree::parseFile(const std::filesystem::path &path) {
  TSParser *parser = ts_parser_new();
  ts_parser_set_language(parser, tree_sitter_meson());
  if (this->overrides.contains(path)) {
    const auto &fileContent = this->overrides[path];
    TSTree *tree = ts_parser_parse_string(parser, nullptr, fileContent.data(),
                                          (uint32_t)fileContent.length());
    auto sourceFile = std::make_shared<MemorySourceFile>(fileContent, path);
    auto rootNode = makeNode(sourceFile, ts_tree_root_node(tree));
    this->ownedFiles.insert(std::filesystem::absolute(path));
    rootNode->setParents();
    if (!this->asts.contains(rootNode->file->file)) {
      this->asts[rootNode->file->file] = {};
    }
    this->asts[rootNode->file->file].push_back(rootNode);
    ts_tree_delete(tree);
    ts_parser_delete(parser);
    return this->asts[rootNode->file->file].back();
  }
  const auto &fileContent = readFile(path);
  TSTree *tree = ts_parser_parse_string(parser, nullptr, fileContent.data(),
                                        (uint32_t)fileContent.length());
  auto sourceFile = std::make_shared<SourceFile>(path);
  auto rootNode = makeNode(sourceFile, ts_tree_root_node(tree));
  if (!this->asts.contains(rootNode->file->file)) {
    this->asts[rootNode->file->file] = {};
  }
  this->ownedFiles.insert(std::filesystem::absolute(path));
  rootNode->setParents();
  this->asts[rootNode->file->file].push_back(rootNode);
  ts_tree_delete(tree);
  ts_parser_delete(parser);
  return this->asts[rootNode->file->file].back();
}

void MesonTree::partialParse(AnalysisOptions analysisOptions) {
  LOG.info(std::format("Parsing {} ({})", this->identifier,
                       this->root.generic_string()));
  // First fetch all the options
  const auto &optState = parseOptions(this->root, &this->metadata);
  // Then fetch diagnostics for the options
  // Then parse the root meson.build file
  const auto &rootFile = this->root / "meson.build";
  if (!std::filesystem::exists(rootFile)) {
    LOG.warn(std::format("No meson.build file in {}", this->root.c_str()));
    return;
  }
  auto rootNode = this->parseFile(rootFile);
  this->scope.variables["meson"] = {this->ns.types.at("meson")};
  this->scope.variables["build_machine"] = {this->ns.types.at("build_machine")};
  this->scope.variables["host_machine"] = {this->ns.types.at("host_machine")};
  this->scope.variables["target_machine"] = {
      this->ns.types.at("target_machine")};
  TypeAnalyzer visitor(this->ns, &this->metadata, this, this->scope,
                       analysisOptions, optState);
  rootNode->setParents();
  rootNode->visit(&visitor);
  this->options = visitor.options;
}
