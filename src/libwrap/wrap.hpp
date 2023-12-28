#pragma once

#include "ini.hpp"

#include <filesystem>
#include <memory>
#include <optional>
#include <string>
#include <utility>
#include <vector>

class Wrap {
public:
  std::optional<std::string> directory;
  std::optional<std::string> patchUrl;
  std::optional<std::string> patchFallbackUrl;
  std::optional<std::string> patchFilename;
  std::optional<std::string> patchHash;
  std::optional<std::string> patchDirectory;

  std::vector<std::string> diffFiles;
  std::optional<std::string> method;
  bool successfullySetup = false;

  virtual bool setupDirectory(std::filesystem::path path,
                              std::filesystem::path packageFilesPath) {
    (void)path;
    (void)packageFilesPath;
    return true;
  }

  virtual ~Wrap() = default;

protected:
  Wrap(ast::ini::Section *section);
  bool postSetup(const std::filesystem::path &path,
                 const std::filesystem::path &packageFilesPath);

private:
  bool applyPatch(const std::filesystem::path &path,
                  const std::filesystem::path &packageFilesPath);
  bool applyDiffFiles(const std::filesystem::path &path,
                      const std::filesystem::path &packageFilesPath);
};

class FileWrap : public Wrap {
public:
  std::string sourceUrl;
  std::optional<std::string> sourceFallbackUrl;
  std::optional<std::string> sourceFilename;
  std::optional<std::string> sourceHash;
  bool leadDirectoryMissing = false;

  FileWrap(ast::ini::Section *section);
  bool setupDirectory(std::filesystem::path path,
                      std::filesystem::path packageFilesPath) override;
};

class VcsWrap : public Wrap {
public:
  std::string url;
  std::string revision;

  VcsWrap(ast::ini::Section *section);
};

class GitWrap : public VcsWrap {
public:
  int depth = 0;
  std::optional<std::string> pushUrl;
  bool cloneRecursive = false;

  GitWrap(ast::ini::Section *node);

  bool setupDirectory(std::filesystem::path path,
                      std::filesystem::path packageFilesPath) override;
};

class HgWrap : public VcsWrap {
public:
  HgWrap(ast::ini::Section *node) : VcsWrap(node) {}

  bool setupDirectory(std::filesystem::path path,
                      std::filesystem::path packageFilesPath) override;
};

class SvnWrap : public VcsWrap {
public:
  SvnWrap(ast::ini::Section *node) : VcsWrap(node) {}

  bool setupDirectory(std::filesystem::path path,
                      std::filesystem::path packageFilesPath) override;
};

class WrapFile {
public:
  std::shared_ptr<Wrap> serializedWrap;
  std::shared_ptr<ast::ini::Node> ast;

  WrapFile(std::shared_ptr<Wrap> serializedWrap,
           std::shared_ptr<ast::ini::Node> ast)
      : serializedWrap(std::move(serializedWrap)), ast(std::move(ast)) {}
};

std::shared_ptr<WrapFile> parseWrap(const std::filesystem::path &path);
