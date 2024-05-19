#pragma once

#include "analysisoptions.hpp"
#include "mesonmetadata.hpp"
#include "node.hpp"
#include "optionstate.hpp"
#include "scope.hpp"
#include "subprojects/subprojectstate.hpp"
#include "tree_sitter/api.h"
#include "typenamespace.hpp"
#include "version.hpp"

#include <filesystem>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

constexpr int MAX_TREE_DEPTH = 3;

class MesonTree {
public:
  std::string identifier = "root";
  std::filesystem::path root;
  std::set<std::filesystem::path> ownedFiles;
  std::map<std::filesystem::path, std::vector<std::shared_ptr<Node>>> asts;
  std::map<std::filesystem::path, std::string> overrides;
  std::map<std::string, TSTree *> savedTrees;
  SubprojectState state;
  Scope scope;
  MesonMetadata metadata;
  OptionState options;
  MesonTree *parent{nullptr};
  const TypeNamespace &ns;
  int depth = 0;
  std::string name = "root";
  Version version = Version("9999.9999.9999");
  bool useCustomParser = false;

  MesonTree(const std::filesystem::path &root, const TypeNamespace &ns)
      : root(root), state(SubprojectState(root)), ns(ns) {}

  void partialParse(AnalysisOptions analysisOptions);

  void fullParse(AnalysisOptions analysisOptions, bool downloadSubprojects) {
    if (this->depth < MAX_TREE_DEPTH) {
      this->parseRootFile();
      this->state.used = true;
      this->state.fullSetup(analysisOptions, depth + 1, this->identifier,
                            this->ns, downloadSubprojects,
                            this->useCustomParser, this);
    }
    this->partialParse(analysisOptions);
  }

  void clear() {
    this->ownedFiles.clear();
    this->asts = {};
    this->metadata.clear();
    this->version = Version("9999.9999.9999");
  }

  std::shared_ptr<Node> parseFile(const std::filesystem::path &path);

  [[nodiscard]] std::vector<const MesonTree *> flatten() const {
    std::vector<const MesonTree *> ret;
    for (const auto &subproj : this->state.subprojects) {
      auto flattened = subproj->tree->flatten();
      ret.insert(ret.end(), flattened.begin(), flattened.end());
    }
    ret.emplace_back(this);
    return ret;
  }

  ~MesonTree() {
    for (const auto &[_, tree] : this->savedTrees) {
      ts_tree_delete(tree);
    }
  }

  MesonTree(const MesonTree &) = delete;
  MesonTree &operator=(const MesonTree &) = delete;

private:
  std::shared_ptr<Node> parseRootFile();
  OptionState parseFile(const std::filesystem::path &path,
                        MesonMetadata *originalMetadata);
  OptionState parseOptions(const std::filesystem::path &treeRoot,
                           MesonMetadata *originalMetadata);
};
