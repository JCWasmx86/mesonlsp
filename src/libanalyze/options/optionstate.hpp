#pragma once

#include "mesonoption.hpp"

#include <memory>
#include <vector>

class OptionState {
public:
  std::vector<std::shared_ptr<MesonOption>> options;

  OptionState();

  OptionState(const std::vector<std::shared_ptr<MesonOption>> &options)
      : OptionState() {
    for (const auto &option : options) {
      this->options.push_back(option);
    }
  }
};
