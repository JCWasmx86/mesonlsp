#pragma once

#include <source_location>
#include <string>

class Logger {
private:
  std::string module;
  std::string red;
  std::string yellow;
  std::string blue;
  std::string reset;

public:
  explicit Logger(std::string module);

  void
  info(const std::string &msg,
       std::source_location location = std::source_location::current()) const;
  void
  error(const std::string &msg,
        std::source_location location = std::source_location::current()) const;
  void
  warn(const std::string &msg,
       std::source_location location = std::source_location::current()) const;
};
