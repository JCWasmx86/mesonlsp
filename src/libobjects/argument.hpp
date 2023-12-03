#pragma once

#include <string>

class Argument
{
public:
  const std::string name;
  const bool optional;

protected:
  Argument (std::string name, bool optional) : name (name), optional (optional)
  {
  }
};

class Kwarg : public Argument
{
public:
  Kwarg (std::string name, bool optional) : Argument (name, optional) {}
};

class PositionalArgument : public Argument
{
public:
  const bool varargs;

  PositionalArgument (std::string name, bool optional, bool varargs)
      : Argument (name, optional), varargs (varargs)
  {
  }
};