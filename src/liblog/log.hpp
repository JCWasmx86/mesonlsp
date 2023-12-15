#pragma once

#include <format>
#include <source_location>
#include <string>

class Logger {
private:
  std::string module;

public:
  Logger(std::string module);

  template <typename... Args>
  void info(const std::string &str, const Args &...args,
            std::source_location location = std::source_location::current()) {
    info(std::format(str, args...), location);
  }
  template <typename... Args>
  void error(const std::string &str, const Args &...args,
             std::source_location location = std::source_location::current()) {
    error(std::format(str, args...), location);
  }
  template <typename... Args>
  void warn(const std::string &str, const Args &...args,
            std::source_location location = std::source_location::current()) {
    warn(std::format(str, args...), location);
  }
  void info(std::string msg,
            std::source_location location = std::source_location::current());
  void error(std::string msg,
             std::source_location location = std::source_location::current());
  void warn(std::string msg,
            std::source_location location = std::source_location::current());
};
