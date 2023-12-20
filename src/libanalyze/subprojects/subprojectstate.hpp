#pragma once
#include "analysisoptions.hpp"
#include "subproject.hpp"
#include "typenamespace.hpp"

#include <filesystem>
#include <memory>
#include <utility>
#include <vector>

class SubprojectState {
public:
  std::filesystem::path root;
  std::vector<std::shared_ptr<MesonSubproject>> subprojects;

  SubprojectState(std::filesystem::path root) : root(std::move(root)) {}

  void findSubprojects();
  void initSubprojects();
  void updateSubprojects();
  void parseSubprojects(AnalysisOptions &options, int depth,
                        const std::string &parentIdentifier,
                        const TypeNamespace &ns);

  void fullSetup(AnalysisOptions &options, int depth,
                 const std::string &parentIdentifier, const TypeNamespace &ns) {
    this->findSubprojects();
    this->initSubprojects();
    this->updateSubprojects();
    this->parseSubprojects(options, depth, parentIdentifier, ns);
  }
};
