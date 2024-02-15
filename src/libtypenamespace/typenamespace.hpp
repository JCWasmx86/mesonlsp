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
  std::map<std::string, std::string> objectDocs;
  std::shared_ptr<Str> strType = std::make_shared<Str>();
  std::shared_ptr<IntType> intType = std::make_shared<IntType>();
  std::shared_ptr<BoolType> boolType = std::make_shared<BoolType>();

  TypeNamespace();

  [[nodiscard]] std::optional<const std::shared_ptr<Function>>
  lookupFunction(const std::string &name) const {
    auto iter = this->functions.find(name);
    if (iter != this->functions.end()) [[likely]] {
      return iter->second;
    }
    return std::nullopt;
  }

  [[nodiscard]] std::optional<const std::shared_ptr<Method>>
  lookupMethod(const std::string &name,
               const std::shared_ptr<Type> &type) const {
    auto iter = this->vtables.find(type->name);
    if (iter != this->vtables.end()) [[likely]] {
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

  [[nodiscard]] std::optional<const std::shared_ptr<Method>>
  lookupMethod(const std::string &name) const {
    for (const auto &[_, methods] : this->vtables) {
      for (const auto &method : methods) {
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
