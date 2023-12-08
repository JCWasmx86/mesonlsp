#pragma once

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
  std::optional<std::string> patchHas;
  std::optional<std::string> patchDirectory;

  std::vector<std::string> diff_files;
  std::optional<std::string> method;
};

class FileWrap : public Wrap {
public:
  std::string sourceUrl;
  std::optional<std::string> sourceFallbackUrl;
  std::optional<std::string> sourceFilename;
  std::optional<std::string> sourceHash;
  bool leadDirectoryMissing = false;
};

class VcsWrap : public Wrap {
public:
  std::string url;
  std::string revision;
};

class GitWrap : public VcsWrap {
public:
  int depth = 0;
  std::optional<std::string> pushUrl;
  bool cloneRecursive = false;
};

class HgWrap : public VcsWrap {};

class SvnWrap : public VcsWrap {};

class WrapFile {
  // TODO: AST
public:
  std::shared_ptr<Wrap> serialized_wrap;
};
