#pragma once

#include <filesystem>
#include <string>
#include <utility>

class MesonSubproject {
public:
  bool initialized = false;
  std::string name;
  std::filesystem::path realpath;

  MesonSubproject(std::string name, std::filesystem::path path)
      : name(std::move(name)), realpath(std::move(path)) {}

  virtual void init() = 0;
  virtual void update() = 0;

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

class WrapSubproject : public MesonSubproject {
public:
  std::filesystem::path wrapFile;
  std::filesystem::path packageFiles;

  WrapSubproject(std::string name, std::filesystem::path wrapFile,
                 std::filesystem::path packageFiles, std::filesystem::path path)
      : MesonSubproject(std::move(name), std::move(path)),
        wrapFile(std::move(wrapFile)), packageFiles(std::move(packageFiles)) {}

  void init() override {
    // Nothing
  }

  void update() override {
    // Nothing
  }
};
