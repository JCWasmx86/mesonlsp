#pragma once
#include "utils.hpp"

#include <algorithm>
#include <string>
#include <vector>

class Version {
public:
  std::string versionString;

  Version(const std::string &string) {
    this->versionString = string;
    this->parts = split(this->versionString, ".");
  }

  bool after(const Version &other) {
    for (unsigned long i = 0;
         i < std::min(other.parts.size(), this->parts.size()); i++) {
      auto thisPart = this->parts[i];
      auto otherPart = other.parts[i];
      if (thisPart > otherPart) {
        return true;
      }
      if (thisPart < otherPart) {
        return false;
      }
    }
    return this->parts.size() > other.parts.size();
  }

private:
  std::vector<std::string> parts;
};
