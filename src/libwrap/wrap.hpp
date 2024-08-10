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
  std::vector<std::string> errors;

  virtual bool setupDirectory(const std::filesystem::path &path,
                              const std::filesystem::path &packageFilesPath) {
    (void)path;
    (void)packageFilesPath;
    return true;
  }

  virtual ~Wrap() = default;

protected:
  explicit Wrap(ast::ini::Section *section);
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

  explicit FileWrap(ast::ini::Section *section);
  bool setupDirectory(const std::filesystem::path &path,
                      const std::filesystem::path &packageFilesPath) override;
};

class VcsWrap : public Wrap {
public:
  std::string url;
  std::string revision;

  explicit VcsWrap(ast::ini::Section *section);
};

class GitWrap : public VcsWrap {
public:
  std::optional<std::string> pushUrl;
  int depth = 0;
  bool cloneRecursive = false;

  explicit GitWrap(ast::ini::Section *node);

  bool setupDirectory(const std::filesystem::path &path,
                      const std::filesystem::path &packageFilesPath) override;
};

class HgWrap : public VcsWrap {
  using VcsWrap::VcsWrap;

public:
  bool setupDirectory(const std::filesystem::path &path,
                      const std::filesystem::path &packageFilesPath) override;
};

class SvnWrap : public VcsWrap {
  using VcsWrap::VcsWrap;

public:
  bool setupDirectory(const std::filesystem::path &path,
                      const std::filesystem::path &packageFilesPath) override;
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
