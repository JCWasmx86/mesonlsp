#pragma once

#include "analysisoptions.hpp"
#include "typenamespace.hpp"
#include "utils.hpp"
#include "wrap.hpp"

#include <filesystem>
#include <fstream>
#include <memory>
#include <string>
#include <utility>

class MesonTree;

class MesonSubproject {
public:
  bool initialized = false;
  std::string name;
  std::filesystem::path realpath;
  std::shared_ptr<MesonTree> tree;

  MesonSubproject(std::string name, std::filesystem::path path)
      : name(std::move(name)), realpath(std::move(path)) {}

  virtual void init() = 0;
  virtual void update() = 0;
  void parse(const AnalysisOptions &options, int depth,
             const std::string &parentIdentifier, const TypeNamespace &ns,
             bool downloadSubprojects, bool useCustomParser);

  virtual ~MesonSubproject() = default;
};

class CachedSubproject : public MesonSubproject {
public:
  CachedSubproject(std::string name, std::filesystem::path path)
      : MesonSubproject(std::move(name), std::move(path)) {
    this->initialized = true;
  }

  void init() override {
    // Nothing
  }

  void update() override {
    // Nothing
  }
};

class FolderSubproject : public MesonSubproject {
public:
  FolderSubproject(std::string name, std::filesystem::path path)
      : MesonSubproject(std::move(name), std::move(path)) {
    this->initialized = true;
  }

  void init() override {
    // Nothing
  }

  void update() override {
    // Nothing
  }
};

// TODO: Move me
static std::string
guessTargetDirectoryFromWrap(const std::filesystem::path &path) {
  if (std::filesystem::exists(path)) {
    std::ifstream file(path.c_str());
    std::string line;
    while (std::getline(file, line)) {
      const auto pos = line.find("directory");
      if (pos == std::string::npos) {
        continue;
      }
      auto directoryValue = line.substr(pos + sizeof("directory") - 1);
      trim(directoryValue);
      if (directoryValue.empty() || directoryValue[0] != '=') {
        continue;
      }
      auto withoutEquals = directoryValue.substr(1);
      trim(withoutEquals);
      return withoutEquals;
    }
  }
  return path.filename().stem().string();
}

class WrapSubproject : public MesonSubproject {
public:
  std::filesystem::path wrapFile;
  std::filesystem::path packageFiles;
  std::shared_ptr<WrapFile> wrap;

  WrapSubproject(std::string name, std::filesystem::path wrapFile,
                 std::filesystem::path packageFiles,
                 const std::filesystem::path &path)
      : MesonSubproject(std::move(name),
                        path / guessTargetDirectoryFromWrap(wrapFile)),
        wrapFile(std::move(wrapFile)), packageFiles(std::move(packageFiles)) {}

  void init() override {
    const auto ptr = parseWrap(this->wrapFile);
    if (!ptr || !ptr->serializedWrap) {
      return;
    }
    const auto result = ptr->serializedWrap->setupDirectory(
        this->realpath.parent_path(), this->packageFiles);
    if (!result) {
      return;
    }
    const auto setupFile = this->realpath.parent_path() / ".fullysetup";
    std::ofstream{setupFile}.put('\n');
    this->initialized = true;
  }

  void update() override {
    // Nothing
  }
};
