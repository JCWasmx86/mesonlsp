#pragma once

#include "ini.hpp"
#include <filesystem>
#include <memory>
#include <optional>
#include <string>
#include <vector>
class Wrap {
public:
  std::optional<std::string> directory;
  std::optional<std::string> patchUrl;
  std::optional<std::string> patchFallbackUrl;
  std::optional<std::string> patchFilename;
  std::optional<std::string> patchHash;
  std::optional<std::string> patchDirectory;

  std::vector<std::string> diff_files;
  std::optional<std::string> method;

  virtual void setupDirectory(std::filesystem::path path,
                              std::filesystem::path packageFilesPath) {}
  virtual ~Wrap() {}

protected:
  Wrap(ast::ini::Section *node);
};

class FileWrap : public Wrap {
public:
  std::string sourceUrl;
  std::optional<std::string> sourceFallbackUrl;
  std::optional<std::string> sourceFilename;
  std::optional<std::string> sourceHash;
  bool leadDirectoryMissing = false;

  FileWrap(ast::ini::Section *node);
};

class VcsWrap : public Wrap {
public:
  std::string url;
  std::string revision;

  VcsWrap(ast::ini::Section *node);
};

class GitWrap : public VcsWrap {
public:
  int depth = 0;
  std::optional<std::string> pushUrl;
  bool cloneRecursive = false;

  GitWrap(ast::ini::Section *node);

  void setupDirectory(std::filesystem::path path,
                      std::filesystem::path packageFilesPath) override;
};

class HgWrap : public VcsWrap {
public:
  HgWrap(ast::ini::Section *node) : VcsWrap(node) {}
  void setupDirectory(std::filesystem::path path,
                      std::filesystem::path packageFilesPath) override;
};

class SvnWrap : public VcsWrap {
public:
  SvnWrap(ast::ini::Section *node) : VcsWrap(node) {}

  void setupDirectory(std::filesystem::path path,
                      std::filesystem::path packageFilesPath) override;
};

class WrapFile {
public:
  std::shared_ptr<Wrap> serialized_wrap;
  std::shared_ptr<ast::ini::Node> ast;

  WrapFile(std::shared_ptr<Wrap> serialized_wrap,
           std::shared_ptr<ast::ini::Node> ast)
      : serialized_wrap(serialized_wrap), ast(ast) {}
};

std::shared_ptr<WrapFile> parse_wrap(std::filesystem::path path);
