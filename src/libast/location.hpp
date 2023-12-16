#pragma once

#include <cstdint>
#include <format>
#include <string>
#include <tree_sitter/api.h>

class Location {
public:
  Location(uint32_t startLine, uint32_t endLine, uint32_t startColumn,
           uint32_t endColumn)
      : startLine(startLine), endLine(endLine), startColumn(startColumn),
        endColumn(endColumn) {}

  Location() : startLine(0), endLine(0), startColumn(0), endColumn(0) {}

  Location(TSNode node)
      : startLine(ts_node_start_point(node).row),
        endLine(ts_node_end_point(node).row),
        startColumn(ts_node_start_point(node).column / 2),
        endColumn(ts_node_end_point(node).column / 2) {}

  const uint32_t startLine;
  const uint32_t endLine;
  const uint32_t startColumn;
  const uint32_t endColumn;

  std::string format() {
    return std::format("[{},{}]->[{}:{}]", this->startLine, this->startColumn,
                       this->endLine, this->endColumn);
  }
};
