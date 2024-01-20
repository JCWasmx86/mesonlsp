#pragma once

#include "mesonoption.hpp"

#include <memory>
#include <string>
#include <vector>

class OptionState {
public:
  std::vector<std::shared_ptr<MesonOption>> options;

  OptionState();

  explicit OptionState(const std::vector<std::shared_ptr<MesonOption>> &options)
      : OptionState() {
    for (const auto &option : options) {
      this->options.push_back(option);
    }
  }

  [[nodiscard]] std::shared_ptr<MesonOption>
  findOption(const std::string &name) const {
    for (const auto &option : this->options) {
      if (option->name == name) {
        return option;
      }
    }
    return nullptr;
  }
};
