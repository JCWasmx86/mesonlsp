#include "sourcefile.hpp"

#include <filesystem>
#include <fstream>
#include <ios>
#include <string>

const std::string &SourceFile::contents() {
  if (this->cached) {
    return this->cachedContents;
  }
  auto path = std::filesystem::path(this->file);
  std::ifstream file(path);
  auto fileSize = std::filesystem::file_size(path);
  this->cachedContents.resize(fileSize, '\0');
  file.read(this->cachedContents.data(), (std::streamsize)fileSize);
  this->cached = true;
  return this->cachedContents;
}
