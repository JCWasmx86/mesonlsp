#pragma once

#include "location.hpp"
#include "utils.hpp"

#include <filesystem>
#include <memory>
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

  virtual std::string extractNodeValue(TSNode node) {
    auto startByte = ts_node_start_byte(node);
    auto endByte = ts_node_end_byte(node);
    return this->contents().substr(startByte, endByte - startByte);
  }

  virtual std::string extractNodeValue(const Location *loc) {
    auto string = this->contents();
    auto lines = split(string, "\n");
    if (loc->startLine == loc->endLine) {
      auto line = lines[loc->startLine];
      return line.substr(loc->startColumn, loc->endColumn - loc->startColumn);
    }
    auto firstLine = lines[loc->startLine];
    auto firstLine1 = firstLine.substr(loc->startColumn);
    auto lastLine = lines[loc->endLine];
    auto lastLine1 = lastLine.substr(0, loc->endColumn);
    std::string concatenated;
    for (size_t idx = loc->startLine + 1; idx < loc->endLine; idx++) {
      concatenated += std::format("{}\n", lines[idx]);
    }
    return firstLine1 + concatenated + lastLine1;
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
