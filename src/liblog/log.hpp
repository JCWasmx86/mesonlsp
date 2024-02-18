#pragma once

#include <source_location>
#include <string>

class Logger {
private:
  std::string logmodule;
  std::string red;
  std::string yellow;
  std::string blue;
  std::string green;
  std::string reset;
  bool noOutput = false;

public:
  explicit Logger(std::string logmodule);

  void
  info(const std::string &msg,
       std::source_location location = std::source_location::current()) const;
  void
  debug(const std::string &msg,
        std::source_location location = std::source_location::current()) const;
  void
  error(const std::string &msg,
        std::source_location location = std::source_location::current()) const;
  void
  warn(const std::string &msg,
       std::source_location location = std::source_location::current()) const;
};
