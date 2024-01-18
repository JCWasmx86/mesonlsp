#pragma once
#include "analysisoptions.hpp"
#include "subproject.hpp"
#include "typenamespace.hpp"

#include <algorithm>
#include <filesystem>
#include <memory>
#include <optional>
#include <string>
#include <utility>
#include <vector>

class SubprojectState {
public:
  std::filesystem::path root;
  std::vector<std::shared_ptr<MesonSubproject>> subprojects;
  bool used = false;

  explicit SubprojectState(std::filesystem::path root)
      : root(std::move(root)) {}

  void findSubprojects(bool downloadSubprojects);
  void initSubprojects();
  void updateSubprojects();
  void parseSubprojects(const AnalysisOptions &options, int depth,
                        const std::string &parentIdentifier,
                        const TypeNamespace &ns, bool downloadSubprojects);

  bool hasSubproject(const std::string &name) const {
    if (!this->used) {
      return false;
    }
    return std::ranges::any_of(
        this->subprojects.begin(), this->subprojects.end(),
        [&name](const auto subproj) { return subproj->name == name; });
  }

  std::shared_ptr<MesonSubproject>
  findSubproject(const std::string &name) const {
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

  void fullSetup(const AnalysisOptions &options, int depth,
                 const std::string &parentIdentifier, const TypeNamespace &ns,
                 bool downloadSubprojects) {
    this->findSubprojects(downloadSubprojects);
    this->initSubprojects();
    this->updateSubprojects();
    this->parseSubprojects(options, depth, parentIdentifier, ns,
                           downloadSubprojects);
  }
};

std::optional<std::string>
createIdentifierForWrap(const std::filesystem::path &path);
