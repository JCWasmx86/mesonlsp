#pragma once

#include "type.hpp"

#include <map>
#include <memory>
#include <string>

class Scope {
public:
  std::map<std::string, std::vector<std::shared_ptr<Type>>> variables;

  Scope() = default;

  Scope(Scope &parent) { this->variables = parent.variables; }
};
