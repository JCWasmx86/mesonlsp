#pragma once

#include "type.hpp"
#include <memory>
#include <string>
#include <vector>

class Argument
{
public:
  const std::string name;
  const std::vector<std::shared_ptr<Type>> types;
  const bool optional;

protected:
  Argument(std::string name,
           std::vector<std::shared_ptr<Type>> types,
           bool optional)
    : name(name)
    , types(types)
    , optional(optional)
  {
  }
};

class Kwarg : public Argument
{
public:
  Kwarg(std::string name,
        std::vector<std::shared_ptr<Type>> types,
        bool optional)
    : Argument(name, types, optional)
  {
  }
};

class PositionalArgument : public Argument
{
public:
  const bool varargs;

  PositionalArgument(std::string name,
                     std::vector<std::shared_ptr<Type>> types,
                     bool optional,
                     bool varargs)
    : Argument(name, types, optional)
    , varargs(varargs)
  {
  }
};