#include "mesontree.hpp"

#include "analysisoptions.hpp"
#include "lexer.hpp"
#include "log.hpp"
#include "mesonmetadata.hpp"
#include "node.hpp"
#include "optiondiagnosticvisitor.hpp"
#include "optionextractor.hpp"
#include "optionstate.hpp"
#include "parser.hpp"
#include "polyfill.hpp"
#include "scope.hpp"
#include "sourcefile.hpp"
#include "typeanalyzer.hpp"
#include "utils.hpp"

#include <chrono> // IWYU pragma: keep Needed for std::formatting std::filesystem::last_write_time result
#include <cstdint>
#include <filesystem>
#include <memory>
#include <string>
#include <tree_sitter/api.h>

extern "C" TSLanguage *tree_sitter_meson(); // NOLINT

const static Logger LOG("analyze::mesontree"); // NOLINT

static std::string createId(const std::filesystem::path &path) {
  using namespace std::chrono_literals;
  const std::filesystem::file_time_type &mtime =
      std::filesystem::last_write_time(path);

  return std::format("{}-{}", path.generic_string(), mtime);
}

OptionState MesonTree::parseFile(const std::filesystem::path &path,
                                 MesonMetadata *originalMetadata) {
  auto visitor = OptionExtractor();
  auto diagnosticVisitor = OptionDiagnosticVisitor(originalMetadata);
  if (this->useCustomParser) {
    LOG.info(std::format("Using custom parser for {}", path.generic_string()));
    const auto overridden = this->overrides.contains(path);
    const auto fileContent =
        overridden ? this->overrides[path] : readFile(path);
    auto sourceFile =
        overridden ? std::make_shared<MemorySourceFile>(fileContent, path)
                   : std::make_shared<SourceFile>(path);
    Lexer lexer(fileContent);
    lexer.tokenize();
    Parser parser(lexer, sourceFile);
    auto rootNode = parser.parse(lexer.errors);
    this->asts[rootNode->file->file] = {rootNode};
    rootNode->setParents();
    rootNode->visit(&visitor);
    rootNode->visit(&diagnosticVisitor);
    return OptionState{visitor.options};
  }
  const auto overridden = this->overrides.contains(path);
  if (!overridden) {
    const auto &fileId = createId(path);
    if (!this->savedTrees.contains(fileId)) {
      LOG.info(std::format("Cache miss for {}", fileId));
      goto slow;
    }
    LOG.info(std::format("Cache hit for {}", fileId));
    const auto *node = this->savedTrees[fileId];
    auto rootNode =
        makeNode(std::make_shared<SourceFile>(path), ts_tree_root_node(node));
    this->asts[rootNode->file->file] = {rootNode};
    rootNode->setParents();
    rootNode->visit(&visitor);
    rootNode->visit(&diagnosticVisitor);
    return OptionState{visitor.options};
  }
  LOG.info(
      std::format("Using contents from editor for {}", path.generic_string()));
slow:
  TSParser *parser = ts_parser_new();
  ts_parser_set_language(parser, tree_sitter_meson());
  const auto fileContent = overridden ? this->overrides[path] : readFile(path);
  TSTree *tree = ts_parser_parse_string(parser, nullptr, fileContent.data(),
                                        (uint32_t)fileContent.length());
  auto sourceFile = overridden
                        ? std::make_shared<MemorySourceFile>(fileContent, path)
                        : std::make_shared<SourceFile>(path);
  auto rootNode = makeNode(sourceFile, ts_tree_root_node(tree));
  this->asts[rootNode->file->file] = {rootNode};
  rootNode->setParents();
  rootNode->visit(&visitor);
  rootNode->visit(&diagnosticVisitor);
  if (!overridden) {
    this->savedTrees[createId(path)] = tree;
  } else {
    ts_tree_delete(tree);
  }
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
  if (this->useCustomParser) {
    LOG.info(std::format("Using custom parser for {}", path.generic_string()));
    const auto overridden = this->overrides.contains(path);
    const auto fileContent =
        overridden ? this->overrides[path] : readFile(path);
    auto sourceFile =
        overridden ? std::make_shared<MemorySourceFile>(fileContent, path)
                   : std::make_shared<SourceFile>(path);
    Lexer lexer(fileContent);
    lexer.tokenize();
    Parser parser(lexer, sourceFile);
    auto rootNode = parser.parse(lexer.errors);
    if (!this->asts.contains(rootNode->file->file)) {
      this->asts[rootNode->file->file] = {};
    }
    this->asts[rootNode->file->file].push_back(rootNode);
    rootNode->setParents();
    return rootNode;
  }
  TSParser *parser = ts_parser_new();
  ts_parser_set_language(parser, tree_sitter_meson());
  if (this->overrides.contains(path)) {
    LOG.info(std::format("Using contents from editor for {}",
                         path.generic_string()));
    const auto fileContent = this->overrides[path];
    TSTree *tree = ts_parser_parse_string(parser, nullptr, fileContent.data(),
                                          (uint32_t)fileContent.length());
    auto sourceFile = std::make_shared<MemorySourceFile>(fileContent, path);
    auto rootNode = makeNode(sourceFile, ts_tree_root_node(tree));
    this->ownedFiles.insert(std::filesystem::absolute(path));
    if (!this->asts.contains(rootNode->file->file)) {
      this->asts[rootNode->file->file] = {};
    }
    this->asts[rootNode->file->file].push_back(rootNode);
    rootNode->setParents();
    ts_tree_delete(tree);
    ts_parser_delete(parser);
    return rootNode;
  }
  const auto &fileId = createId(path);
  if (this->savedTrees.contains(fileId)) {
    LOG.info(std::format("Cache hit for {}", fileId));
    const auto *node = this->savedTrees[fileId];
    auto rootNode =
        makeNode(std::make_shared<SourceFile>(path), ts_tree_root_node(node));
    this->asts[rootNode->file->file] = {rootNode};
    rootNode->setParents();
    if (!this->asts.contains(rootNode->file->file)) {
      this->asts[rootNode->file->file] = {};
    }
    this->asts[rootNode->file->file].push_back(rootNode);
    this->ownedFiles.insert(std::filesystem::absolute(path));
    return rootNode;
  }
  LOG.info(std::format("Cache miss for {}", fileId));
  const auto fileContent = readFile(path);
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
  this->savedTrees[createId(path)] = tree;
  ts_parser_delete(parser);
  return rootNode;
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
