#pragma once

#include "location.hpp"
#include "utils.hpp"

#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <format>
#include <string>
#include <tree_sitter/api.h>
#include <utility>

class SourceFile {
public:
  const std::filesystem::path file;

  SourceFile(const std::filesystem::path &file)
      : file(std::filesystem::absolute(file)) {}

  virtual const std::string &contents();
  virtual ~SourceFile() = default;

  std::string extractNodeValue(const TSNode &node) {
    auto startByte = ts_node_start_byte(node);
    auto endByte = ts_node_end_byte(node);
    return this->extractNodeValue(startByte, endByte);
  }

  std::string extractNodeValue(uint32_t startByte, uint32_t endByte) {
    const auto &contents = this->contents();
    return contents.substr(startByte, endByte - startByte);
  }

  std::string extractNodeValue(const Location &loc) {
    const auto &string = this->contents();
    const auto &lines = split(string, "\n");
    if (loc.startLine == loc.endLine) {
      const auto &line = lines[loc.startLine];
      return line.substr(loc.startColumn, loc.endColumn - loc.startColumn);
    }
    const auto &firstLine = lines[loc.startLine];
    const auto &firstLine1 = firstLine.substr(loc.startColumn);
    const auto &lastLine = lines[loc.endLine];
    const auto &lastLine1 = lastLine.substr(0, loc.endColumn);
    std::string concatenated;
    for (size_t idx = loc.startLine + 1; idx < loc.endLine; idx++) {
      concatenated += std::format("{}\n", lines[idx]);
    }
    return std::format("{}\n{}{}", firstLine1, concatenated, lastLine1);
  }

private:
  std::string cachedContents;
  bool cached = false;
};

class MemorySourceFile : public SourceFile {
private:
  std::string str;

public:
  MemorySourceFile(std::string contents, const std::filesystem::path &file)
      : SourceFile(file), str(std::move(contents)) {}

  const std::string &contents() override { return this->str; }
};
