#include "sourcefile.hpp"

#include <filesystem>
#include <fstream>
#include <ios>
#include <string>

const std::string &SourceFile::contents() {
  if (this->cached) {
    return this->cachedContents;
  }
  const auto &path = std::filesystem::path(this->file);
  std::ifstream fstream(path);
  auto fileSize = std::filesystem::file_size(path);
  this->cachedContents.resize(fileSize, '\0');
  fstream.read(this->cachedContents.data(), (std::streamsize)fileSize);
  this->cached = true;
  return this->cachedContents;
}
