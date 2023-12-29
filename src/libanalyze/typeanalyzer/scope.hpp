#pragma once

#include "type.hpp"

#include <map>
#include <memory>
#include <optional>
#include <string>
#include <vector>

class Scope {
public:
  std::map<std::string, std::vector<std::shared_ptr<Type>>> variables;

  std::optional<std::string>
  findVariableOfType(const std::shared_ptr<Type> &expected) const {
    for (const auto &pair : this->variables) {
      for (const auto &type : pair.second) {
        if (type->toString() == expected->toString()) {
          return pair.first;
        }
      }
    }
    return std::nullopt;
  }
};
