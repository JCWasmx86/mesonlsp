#pragma once

#include "argument.hpp"
#include "deprecationstate.hpp"
#include "type.hpp"
#include "version.hpp"

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
  DeprecationState deprecationState;
  Version since;

  Function(std::string name, std::string doc,
           const std::vector<std::shared_ptr<Argument>> &args,
           const std::vector<std::shared_ptr<Type>> &returnTypes,
           DeprecationState deprecationState = {},
           Version since = Version("0.0.0"))
      : name(std::move(name)), doc(std::move(doc)), args(args),
        returnTypes(returnTypes), deprecationState(std::move(deprecationState)),
        since(std::move(since)) {
    uint32_t minPosArgsCnter = 0;
    for (const auto &arg : args) {
      const auto *pa = dynamic_cast<PositionalArgument *>(arg.get());
      if (pa) {
        if (pa->optional) {
          break;
        }
        minPosArgsCnter++;
      }
    }
    uint32_t maxPosArgsCnter = 0;
    for (const auto &arg : args) {
      const auto *pa = dynamic_cast<PositionalArgument *>(arg.get());
      if (pa) {
        if (pa->varargs) {
          maxPosArgsCnter = UINT32_MAX;
          break;
        }
        maxPosArgsCnter++;
      }
    }
    for (const auto &arg : args) {
      const auto *kw = dynamic_cast<Kwarg *>(arg.get());
      if (!kw) {
        continue;
      }
      this->kwargs[kw->name] = arg;
      if (!kw->optional) {
        this->requiredKwargs.insert(kw->name);
      }
    }
    this->minPosArgs = minPosArgsCnter;
    this->maxPosArgs = maxPosArgsCnter;
  }

  virtual const std::string &id() const;

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

  virtual ~Function() = default;

  Function(const Function &) = delete;
  Function &operator=(const Function &) = delete;
};

class Method : public Function {
public:
  const std::shared_ptr<Type> parentType;

  Method(std::string name, std::string doc,
         const std::vector<std::shared_ptr<Argument>> &args,
         const std::vector<std::shared_ptr<Type>> &returnTypes,
         const std::shared_ptr<Type> &parentType,
         DeprecationState deprecationState = {},
         Version since = Version("0.0.0"))
      : Function(std::move(name), std::move(doc), args, returnTypes,
                 std::move(deprecationState), std::move(since)),
        parentType(parentType),
        privateId(this->parentType->name + "." + this->name) {}

  const std::string &id() const override;

  Method(const Method &) = delete;
  Method &operator=(const Method &) = delete;

private:
  std::string privateId;
};
