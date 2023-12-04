#pragma once

#include <iostream>
#include <source_location>
#include <string>

class Logger {
private:
  std::string module;

public:
  Logger(std::string module);
  void
  info(std::string msg,
       const std::source_location location = std::source_location::current());
  void
  error(std::string msg,
        const std::source_location location = std::source_location::current());
  void
  warn(std::string msg,
       const std::source_location location = std::source_location::current());
};