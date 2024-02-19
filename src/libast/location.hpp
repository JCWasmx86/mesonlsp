#pragma once

#include "polyfill.hpp"

#include <cstdint>
#include <string>
#include <tree_sitter/api.h>

constexpr auto HALF_OF_U64 = 32U;

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

  Location(const std::pair<uint32_t, uint32_t> &start,
           const std::pair<uint32_t, uint32_t> &end)
      : Location(start.first, end.first, start.second, end.second) {}

  Location(const Location &start, const Location &end)
      : Location(start.startLine, end.endLine, start.startColumn,
                 end.endColumn) {}

  Location(const std::pair<uint32_t, uint32_t> &start, const Location &end)
      : Location(start.first, end.endLine, start.second, end.endColumn) {}

  explicit Location(const TSNode &node)
      : startLine(ts_node_start_point(node).row),
        endLine(node.id ? (ts_node_end_point(node).row) : 0),
        startColumn(ts_node_start_point(node).column),
        endColumn(node.id ? (ts_node_end_point(node).column) : 0),
        columns((this->startColumn) |
                (((uint64_t)this->endColumn) << HALF_OF_U64)),
        lines((this->startLine) | (((uint64_t)this->endLine) << HALF_OF_U64)) {}

  const uint32_t startLine;
  const uint32_t endLine;
  const uint32_t startColumn;
  const uint32_t endColumn;
  const uint64_t columns;
  const uint64_t lines;

  [[nodiscard]] std::string format() const {
    return std::format("[{}:{}]->[{}:{}]", this->startLine, this->startColumn,
                       this->endLine, this->endColumn);
  }
};
