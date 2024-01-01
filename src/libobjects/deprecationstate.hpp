#pragma once

#include "version.hpp"

#include <optional>
#include <string>
#include <vector>

class DeprecationState {
public:
  const bool deprecated;
  const std::optional<Version> sinceWhen;
  const std::vector<std::string> replacements;

  DeprecationState() : deprecated(false) {}

  DeprecationState(const std::string &sinceWhen,
                   const std::vector<std::string> &replacements)
      : deprecated(true), sinceWhen(sinceWhen), replacements(replacements) {}
};
