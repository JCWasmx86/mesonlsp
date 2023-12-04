#pragma once

#include <cstdint>
#include <format>
#include <string>

class Location
{
public:
  Location(uint32_t startLine,
           uint32_t endLine,
           uint32_t startColumn,
           uint32_t endColumn)
    : startLine(startLine)
    , endLine(endLine)
    , startColumn(startColumn)
    , endColumn(endColumn)
  {
  }

  Location()
    : startLine(0)
    , endLine(0)
    , startColumn(0)
    , endColumn(0)
  {
  }
  const uint32_t startLine;
  const uint32_t endLine;
  const uint32_t startColumn;
  const uint32_t endColumn;

  std::string format()
  {
    return std::format("[{},{}]->[{}:{}]",
                       this->startLine,
                       this->startColumn,
                       this->endLine,
                       this->endColumn);
  }
};