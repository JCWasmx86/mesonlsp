#include "sourcefile.hpp"

#include <filesystem>
#include <fstream>
#include <ios>
#include <string>

std::string SourceFile::contents() {
  if (this->cached) {
    return this->cached_contents;
  }
  auto path = std::filesystem::path(this->file);
  std::ifstream file(path);
  auto fileSize = std::filesystem::file_size(path);
  std::string fileContent;
  fileContent.resize(fileSize, '\0');
  file.read(fileContent.data(), (std::streamsize)fileSize);
  this->cached = true;
  this->cached_contents = fileContent;
  return fileContent;
}
