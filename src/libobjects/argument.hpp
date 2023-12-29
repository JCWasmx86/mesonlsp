#pragma once

#include "deprecationstate.hpp"
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
  const DeprecationState deprecationState;
  virtual ~Argument() = default;

protected:
  Argument(std::string name, std::vector<std::shared_ptr<Type>> types,
           bool optional, DeprecationState deprecationState = {})
      : name(std::move(name)), types(std::move(types)), optional(optional),
        deprecationState(std::move(deprecationState)) {}
};

class Kwarg : public Argument {
public:
  Kwarg(std::string name, std::vector<std::shared_ptr<Type>> types,
        bool optional, DeprecationState deprecationState = {})
      : Argument(std::move(name), std::move(types), optional,
                 std::move(deprecationState)) {}
};

class PositionalArgument : public Argument {
public:
  const bool varargs;

  PositionalArgument(std::string name, std::vector<std::shared_ptr<Type>> types,
                     bool optional, bool varargs)
      : Argument(std::move(name), std::move(types), optional),
        varargs(varargs) {}
};
