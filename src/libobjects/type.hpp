#pragma once

#include "function.hpp"
#include <string>

class Type
{
public:
  const std::string name;
  virtual const std::string
  to_string ()
  {
    return this->name;
  }

protected:
  Type (std::string name) : name (name) {}
};

class AbstractObject : public Type
{
};

class Any : public Type
{
public:
  Any () : Type ("any") {}
};

class BoolType : public Type
{
public:
  BoolType () : Type ("bool") {}
};

class IntType : public Type
{
public:
  IntType () : Type ("int") {}
};

class Str : public Type
{
public:
  Str () : Type ("str") {}
};