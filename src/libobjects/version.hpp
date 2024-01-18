#pragma once
#include "utils.hpp"

#include <algorithm>
#include <string>
#include <utility>
#include <vector>

class Version {
public:
  std::string versionString;

  explicit Version(std::string string) : versionString(std::move(string)) {
    this->parts = split(this->versionString, ".");
  }

  bool after(const Version &other) {
    for (unsigned long i = 0;
         i < std::min(other.parts.size(), this->parts.size()); i++) {
      const auto &thisPart = this->parts[i];
      const auto &otherPart = other.parts[i];
      if (thisPart > otherPart) {
        return true;
      }
      if (thisPart < otherPart) {
        return false;
      }
    }
    if (this->parts.size() > other.parts.size() && this->parts.back() == "0") {
      return false;
    }
    return this->parts.size() > other.parts.size();
  }

private:
  std::vector<std::string> parts;
};
