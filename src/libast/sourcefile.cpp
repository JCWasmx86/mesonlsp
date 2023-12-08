#include "sourcefile.hpp"
#include <fstream>

std::string SourceFile::contents() {
  if (this->cached) {
    return this->cached_contents;
  }
  auto path = std::filesystem::path(this->file);
  std::ifstream file(path);
  auto file_size = std::filesystem::file_size(path);
  std::string file_content;
  file_content.resize(file_size, '\0');
  file.read(file_content.data(), file_size);
  this->cached = true;
  this->cached_contents = file_content;
  return file_content;
}