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

  [[nodiscard]] std::optional<std::string>
  findVariableOfType(const std::shared_ptr<Type> &expected) const {
    for (const auto &[name, types] : this->variables) {
      for (const auto &type : types) {
        if (type->toString() == expected->toString()) {
          return name;
        }
      }
    }
    return std::nullopt;
  }
};
