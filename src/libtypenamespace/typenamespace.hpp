#pragma once

#include "function.hpp"
#include "type.hpp"

#include <map>
#include <memory>
#include <optional>
#include <string>
#include <vector>

class TypeNamespace {
public:
  std::map<std::string, std::shared_ptr<Function>> functions;
  std::map<std::string, std::shared_ptr<Type>> types;
  std::map<std::string, std::vector<std::shared_ptr<Method>>> vtables;
  std::shared_ptr<Str> strType;
  std::shared_ptr<IntType> intType;
  std::shared_ptr<BoolType> boolType;

  TypeNamespace();

  std::optional<std::shared_ptr<Function>> lookupFunction(std::string &name) {
    if (this->functions.contains(name)) {
      return this->functions[name];
    }
    return std::nullopt;
  }

private:
  void initFunctions();
  void initMethods();
};
