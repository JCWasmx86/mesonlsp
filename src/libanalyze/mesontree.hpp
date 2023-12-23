#pragma once

#include "analysisoptions.hpp"
#include "mesonmetadata.hpp"
#include "node.hpp"
#include "scope.hpp"
#include "subprojects/subprojectstate.hpp"
#include "typenamespace.hpp"

#include <filesystem>
#include <set>

#define MAX_TREE_DEPTH 3

class MesonTree {
public:
  std::string identifier;
  std::filesystem::path root;
  std::set<std::filesystem::path> ownedFiles;
  std::map<std::filesystem::path, std::shared_ptr<Node>> asts;
  std::map<std::filesystem::path, std::string> overrides;
  SubprojectState *state;
  Scope scope;
  MesonMetadata metadata;
  const TypeNamespace &ns;
  int depth = 0;

  MesonTree(const std::filesystem::path &root, const TypeNamespace &ns)
      : identifier("root"), root(root), state(new SubprojectState(root)),
        ns(ns) {}

  ~MesonTree() {
    delete this->state;
    this->state = nullptr;
  }

  void partialParse(AnalysisOptions analysisOptions);

  void fullParse(AnalysisOptions analysisOptions) {
    if (this->depth < MAX_TREE_DEPTH) {
      this->state->used = true;
      this->state->fullSetup(analysisOptions, depth + 1, this->identifier,
                             this->ns);
    }
    this->partialParse(analysisOptions);
  }

  void clear() {
    this->ownedFiles.clear();
    this->asts = {};
    this->metadata.clear();
  }

  std::shared_ptr<Node> parseFile(std::filesystem::path path);
};
