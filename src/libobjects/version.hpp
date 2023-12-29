#pragma once
#include <string>

class Version {
public:
  std::string versionString;

  Version(const std::string &string) {
    this->versionString = string;
  }
};
