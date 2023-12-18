#pragma once

#include <cstdint>
#include <format>
#include <string>
#include <tree_sitter/api.h>

#define HALF_OF_U64 32U

class Location {
public:
  Location(uint32_t startLine, uint32_t endLine, uint32_t startColumn,
           uint32_t endColumn)
      : startLine(startLine), endLine(endLine), startColumn(startColumn),
        endColumn(endColumn),
        columns((this->startColumn) |
                (((uint64_t)this->endColumn) << HALF_OF_U64)),
        lines((this->startLine) | (((uint64_t)this->endLine) << HALF_OF_U64)) {}

  Location()
      : startLine(0), endLine(0), startColumn(0), endColumn(0), columns(0),
        lines(0) {}

  Location(TSNode node)
      : startLine(ts_node_start_point(node).row),
        endLine(ts_node_end_point(node).row),
        startColumn(ts_node_start_point(node).column / 2),
        endColumn(ts_node_end_point(node).column / 2),
        columns((this->startColumn) |
                (((uint64_t)this->endColumn) << HALF_OF_U64)),
        lines((this->startLine) | (((uint64_t)this->endLine) << HALF_OF_U64)) {}

  const uint32_t startLine;
  const uint32_t endLine;
  const uint32_t startColumn;
  const uint32_t endColumn;
  const uint64_t columns;
  const uint64_t lines;

  std::string format() {
    return std::format("[{},{}]->[{}:{}]", this->startLine, this->startColumn,
                       this->endLine, this->endColumn);
  }
};
