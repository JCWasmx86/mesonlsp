#pragma once

#include <filesystem>
#include <string>
#include <tree_sitter/api.h>

class SourceFile {
public:
  const std::filesystem::path file;

  SourceFile(std::filesystem::path file) : file(file) {}
  virtual std::string contents();
  virtual ~SourceFile() = default;
  virtual std::string extract_node_value(TSNode node) {
    auto start_byte = ts_node_start_byte(node);
    auto end_byte = ts_node_end_byte(node);
    return this->contents().substr(start_byte, end_byte - start_byte);
  }

private:
  std::string cached_contents;
  bool cached = false;
};

class MemorySourceFile : public SourceFile {
private:
  std::string str;

public:
  MemorySourceFile(std::string contents, std::filesystem::path file)
      : SourceFile(file), str(contents) {}
  std::string contents() override { return this->str; }
};
