#pragma once

#include "type.hpp"

#include <memory>
#include <string>
#include <utility>
#include <vector>

class Argument {
public:
  const std::string name;
  const std::vector<std::shared_ptr<Type>> types;
  const bool optional;
  virtual ~Argument() = default;

protected:
  Argument(std::string name, std::vector<std::shared_ptr<Type>> types,
           bool optional)
      : name(std::move(name)), types(std::move(types)), optional(optional) {}
};

class Kwarg : public Argument {
public:
  Kwarg(std::string name, std::vector<std::shared_ptr<Type>> types,
        bool optional)
      : Argument(std::move(name), std::move(types), optional) {}
};

class PositionalArgument : public Argument {
public:
  const bool varargs;

  PositionalArgument(std::string name, std::vector<std::shared_ptr<Type>> types,
                     bool optional, bool varargs)
      : Argument(std::move(name), std::move(types), optional),
        varargs(varargs) {}
};
