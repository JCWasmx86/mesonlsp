#pragma once

#include "type.hpp"

#include <map>
#include <memory>
#include <string>
#include <vector>

class Scope {
public:
  std::map<std::string, std::vector<std::shared_ptr<Type>>> variables;
};
