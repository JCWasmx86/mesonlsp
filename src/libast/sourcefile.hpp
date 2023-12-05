#pragma once

#include <filesystem>

class MesonSourceFile {
public:
  const std::filesystem::path file;

  MesonSourceFile(std::filesystem::path file) : file(file) {}
  virtual std::string contents();
  virtual ~MesonSourceFile() = default;

private:
  std::string cached_contents;
  bool cached = false;
};