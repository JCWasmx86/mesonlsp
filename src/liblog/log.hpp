#pragma once

#include <source_location>
#include <string>

class Logger {
private:
  std::string module;

public:
  Logger(std::string module);

  void info(const std::string &msg,
            std::source_location location = std::source_location::current());
  void error(const std::string &msg,
             std::source_location location = std::source_location::current());
  void warn(const std::string &msg,
            std::source_location location = std::source_location::current());
};
