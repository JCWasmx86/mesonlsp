#pragma once

#include "analysisoptions.hpp"
#include "mesonmetadata.hpp"
#include "subprojects/subprojectstate.hpp"
#include "typenamespace.hpp"

#include <filesystem>
#include <set>

class MesonTree {
public:
  std::filesystem::path root;
  std::set<std::filesystem::path> ownedFiles;
  SubprojectState *state;
  MesonMetadata metadata;
  TypeNamespace ns;

  MesonTree(const std::filesystem::path &root)
      : root(root), state(new SubprojectState(root)) {}

  ~MesonTree() {
    delete this->state;
    this->state = nullptr;
  }

  void partialParse(AnalysisOptions analysisOptions);

  void fullParse(AnalysisOptions analysisOptions) {
    this->state->fullSetup();
    this->partialParse(analysisOptions);
  }
};
