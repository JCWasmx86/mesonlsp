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
  std::shared_ptr<Str> strType = std::make_shared<Str>();
  std::shared_ptr<IntType> intType = std::make_shared<IntType>();
  std::shared_ptr<BoolType> boolType = std::make_shared<BoolType>();

  TypeNamespace();

  std::optional<const std::shared_ptr<Function>>
  lookupFunction(const std::string &name) const {
    if (this->functions.contains(name)) {
      return this->functions.at(name);
    }
    return std::nullopt;
  }

  std::optional<const std::shared_ptr<Method>>
  lookupMethod(const std::string &name,
               const std::shared_ptr<Type> &type) const {
    if (this->vtables.contains(type->name)) {
      for (const auto &method : this->vtables.at(type->name)) {
        if (method->name == name) {
          return method;
        }
      }
    }
    auto *abstractObject = dynamic_cast<AbstractObject *>(type.get());
    if (abstractObject && abstractObject->parent) {
      return this->lookupMethod(name, abstractObject->parent.value());
    }
    return std::nullopt;
  }

  std::optional<const std::shared_ptr<Method>>
  lookupMethod(const std::string &name) const {
    for (const auto &vtable : this->vtables) {
      for (const auto &method : vtable.second) {
        if (method->name == name) {
          return method;
        }
      }
    }
    return std::nullopt;
  }

private:
  void initFunctions();
  void initMethods();
  void initObjectDocs();
};
