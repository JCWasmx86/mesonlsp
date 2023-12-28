#pragma once

#include "argument.hpp"
#include "type.hpp"

#include <cstddef>
#include <cstdint>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <utility>
#include <vector>

class Argument;

class Function {
public:
  const std::string name;
  const std::string doc;
  const std::vector<std::shared_ptr<Argument>> args;
  std::map<std::string, std::shared_ptr<Argument>> kwargs;
  const std::vector<std::shared_ptr<Type>> returnTypes;
  uint32_t minPosArgs;
  uint32_t maxPosArgs;
  std::set<std::string> requiredKwargs;

  Function(std::string name, std::string doc,
           std::vector<std::shared_ptr<Argument>> args,
           const std::vector<std::shared_ptr<Type>> returnTypes)
      : name(std::move(name)), doc(std::move(doc)), args(args),
        returnTypes(returnTypes) {
    uint32_t minPosArgs = 0;
    for (const auto &arg : args) {
      auto *pa = dynamic_cast<PositionalArgument *>(arg.get());
      if (pa) {
        if (pa->optional) {
          break;
        }
        minPosArgs++;
      }
    }
    uint32_t maxPosArgs = 0;
    for (const auto &arg : args) {
      auto *pa = dynamic_cast<PositionalArgument *>(arg.get());
      if (pa) {
        if (pa->varargs) {
          maxPosArgs = UINT32_MAX;
          break;
        }
        maxPosArgs++;
      }
    }
    for (const auto &arg : args) {
      auto *kw = dynamic_cast<Kwarg *>(arg.get());
      if (!kw) {
        continue;
      }
      this->kwargs[kw->name] = arg;
      if (!kw->optional) {
        this->requiredKwargs.insert(kw->name);
      }
    }
    this->minPosArgs = minPosArgs;
    this->maxPosArgs = maxPosArgs;
  }

  virtual std::string id();

  PositionalArgument *posArg(size_t posArgsIdx) {
    PositionalArgument *last = nullptr;
    size_t idx = 0;
    for (const auto &rawArg : this->args) {
      if (auto *arg = dynamic_cast<PositionalArgument *>(rawArg.get())) {
        if (posArgsIdx == idx) {
          return arg;
        }
        last = arg;
        idx++;
      }
    }
    return last;
  }

  virtual ~Function() {}
};

class Method : public Function {
public:
  const std::shared_ptr<Type> parentType;

  Method(std::string name, std::string doc,
         std::vector<std::shared_ptr<Argument>> args,
         const std::vector<std::shared_ptr<Type>> returnTypes,
         const std::shared_ptr<Type> parentType)
      : Function(std::move(name), std::move(doc), std::move(args), returnTypes),
        parentType(parentType) {}

  std::string id() override;
};
