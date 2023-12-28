#pragma once
#include "analysisoptions.hpp"
#include "subproject.hpp"
#include "typenamespace.hpp"

#include <filesystem>
#include <memory>
#include <string>
#include <utility>
#include <vector>

class SubprojectState {
public:
  std::filesystem::path root;
  std::vector<std::shared_ptr<MesonSubproject>> subprojects;
  bool used = false;

  SubprojectState(std::filesystem::path root) : root(std::move(root)) {}

  void findSubprojects();
  void initSubprojects();
  void updateSubprojects();
  void parseSubprojects(AnalysisOptions &options, int depth,
                        const std::string &parentIdentifier,
                        const TypeNamespace &ns);

  bool hasSubproject(const std::string &name) {
    if (!this->used) {
      return false;
    }
    for (const auto &subproj : this->subprojects) {
      if (subproj->name == name) {
        return true;
      }
    }
    return false;
  }

  std::shared_ptr<MesonSubproject> findSubproject(const std::string &name) {
    if (!this->used) {
      return nullptr;
    }
    for (const auto &subproj : this->subprojects) {
      if (subproj->name == name) {
        return subproj;
      }
    }
    return nullptr;
  }

  void fullSetup(AnalysisOptions &options, int depth,
                 const std::string &parentIdentifier, const TypeNamespace &ns) {
    this->findSubprojects();
    this->initSubprojects();
    this->updateSubprojects();
    this->parseSubprojects(options, depth, parentIdentifier, ns);
  }
};
