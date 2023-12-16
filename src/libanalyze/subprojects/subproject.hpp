#pragma once

#include <filesystem>
#include <string>

class MesonSubproject {
public:
  bool initialized = false;
  std::string name;
  std::filesystem::path realpath;

  virtual void init() = 0;
  virtual void update() = 0;
};
