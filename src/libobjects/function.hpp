#pragma once
#include "argument.hpp"
#include <cstdint>
#include <map>
#include <memory>
#include <string>
#include <vector>

class Function
{
public:
  const std::string name;
  const std::vector<std::shared_ptr<Argument>> args;
  const std::map<std::string, std::shared_ptr<Argument>> kwargs;

  virtual const std::string id();

protected:
  const uint32_t minPosArgs;
  const uint32_t maxPosArgs;
  const std::vector<std::string> requiredKwargs;
};

class Method : public Function
{
  const std::string id() override;
};