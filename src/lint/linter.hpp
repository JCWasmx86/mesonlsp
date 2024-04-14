#pragma once
#include "lintingconfig.hpp"
#include "mesontree.hpp"
#include "typenamespace.hpp"

#include <filesystem>
#include <string>
#include <utility>

class Linter {
  MesonLintConfig config;
  std::filesystem::path root;
  MesonTree tree;
  TypeNamespace ns;
  std::filesystem::path muonConfigFile;
  std::map<std::filesystem::path, std::string> unformattedFiles;

public:
  Linter(MesonLintConfig cfg, std::filesystem::path root)
      : config(std::move(cfg)), root(std::move(root)),
        tree(this->root, this->ns) {}

  bool lint() {
    const auto passedCodeLinting = this->lintCode();
    const auto passedFormattingLinting = this->lintFormatting();
    if (passedCodeLinting && passedFormattingLinting) {
      std::cout << "Your project passes all tests ✨ 🍰 ✨" << std::endl;
      return true;
    }
    this->printDiagnostics();
    return false;
  }

  void fix();

private:
  bool lintCode();
  bool lintFormatting();
  void lintFormattingTracked();
  void lintFormatting(const std::filesystem::path &path);
  void writeMuonConfigFile();
  void printDiagnostics() const;
};
