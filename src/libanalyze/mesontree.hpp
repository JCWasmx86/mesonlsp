#pragma once

#include "analysisoptions.hpp"
#include "mesonmetadata.hpp"
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
  SubprojectState *state;
  MesonMetadata metadata;
  TypeNamespace ns;
  int depth = 0;

  MesonTree(const std::filesystem::path &root)
      : identifier("root"), root(root), state(new SubprojectState(root)) {}

  ~MesonTree() {
    delete this->state;
    this->state = nullptr;
  }

  void partialParse(AnalysisOptions analysisOptions);

  void fullParse(AnalysisOptions analysisOptions) {
    if (this->depth < MAX_TREE_DEPTH) {
      this->state->fullSetup(analysisOptions, depth + 1, this->identifier);
    }
    this->partialParse(analysisOptions);
  }

  std::shared_ptr<Node> parseFile(std::filesystem::path path);
};
