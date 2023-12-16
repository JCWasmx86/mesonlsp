#include "optionstate.hpp"
#include "mesonoption.hpp"
#include <memory>

OptionState::OptionState() {
  this->options.push_back(std::make_shared<StringOption>(
      "prefix", "Installation prefix (`C:\\` or `/usr/local` by default)"));
  this->options.push_back(std::make_shared<StringOption>(
      "bindir", "Executable directory (Default: `bin`)"));
  this->options.push_back(std::make_shared<StringOption>(
      "datadir", "Executable directory (Default: `share`)"));
  this->options.push_back(std::make_shared<StringOption>(
      "includedir", "Executable directory (Default: `include`)"));
}
