#pragma once
#include "utils.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <string>
#include <utility>

class Version {
public:
  std::string versionString;

  explicit Version(std::string string) : versionString(std::move(string)) {
    const auto partsStr = split(this->versionString, ".");
    try {
        for(std::size_t i = 0; i < std::min(parts.size(), partsStr.size()); ++i) {
        parts[i] = std::stoul(partsStr[i]);
    }}
    catch(const std::exception&) {}
  }

  bool after(const Version &other) {
    for (std::size_t i = 0; i < 3; ++i) {
      const auto &thisPart = this->parts[i];
      const auto &otherPart = other.parts[i];
      if (thisPart > otherPart) {
        return true;
      }
      if (thisPart < otherPart) {
        return false;
      }
    }
    return false;
  }

private:
  std::array<unsigned long, 3> parts;
};
