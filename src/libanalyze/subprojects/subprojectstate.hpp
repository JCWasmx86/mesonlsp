#pragma once
#include "subproject.hpp"
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

  void fullSetup() {
    this->findSubprojects();
    this->initSubprojects();
    this->updateSubprojects();
  }
};
