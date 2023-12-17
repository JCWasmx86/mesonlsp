#pragma once

#include <filesystem>
#include <string>
#include <tree_sitter/api.h>
#include <utility>

class SourceFile {
public:
  const std::filesystem::path file;

  SourceFile(const std::filesystem::path &file)
      : file(std::filesystem::absolute(file)) {}

  virtual std::string contents();
  virtual ~SourceFile() = default;

  virtual std::string extractNodeValue(TSNode node) {
    auto startByte = ts_node_start_byte(node);
    auto endByte = ts_node_end_byte(node);
    return this->contents().substr(startByte, endByte - startByte);
  }

private:
  std::string cached_contents;
  bool cached = false;
};

class MemorySourceFile : public SourceFile {
private:
  std::string str;

public:
  MemorySourceFile(std::string contents, const std::filesystem::path &file)
      : SourceFile(file), str(std::move(contents)) {}

  std::string contents() override { return this->str; }
};
