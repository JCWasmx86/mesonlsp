#pragma once

#include <filesystem>

class MesonSourceFile
{
public:
  std::filesystem::path file;

private:
  std::string cached_contents;
  bool cached = false;

  MesonSourceFile(std::filesystem::path file)
    : file(file)
  {
  }

  virtual std::string contents();
};