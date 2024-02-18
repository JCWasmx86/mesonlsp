#include "log.hpp"

#include <cstdlib>
#include <exception>
#include <format>
#include <iostream>
#include <source_location>
#include <string>
#include <unistd.h>
#include <utility>

Logger::Logger(std::string logmodule) : logmodule(std::move(logmodule)) {
  this->noOutput = getenv("MESONLSP_NO_LOG") != nullptr;
  if (isatty(STDERR_FILENO) != 0) {
    this->blue = "\033[96m";
    this->red = "\033[91m";
    this->yellow = "\033[93m";
    this->reset = "\033[0m";
    this->green = "\033[1;92m";
  } else {
    this->blue = "";
    this->red = "";
    this->yellow = "";
    this->reset = "";
  }
}

void Logger::error(const std::string &msg,
                   const std::source_location location) const {
  auto fullMsg =
      std::format("{}[ ERROR ] {} - {}:{}: {}", this->red, this->logmodule,
                  location.file_name(), location.line(), msg);
  std::clog << fullMsg;
  auto eptr = std::current_exception();
  if (eptr) {
    try {
      std::rethrow_exception(eptr);
    } catch (const std::exception &exc) {
      std::clog << "\n\tException: " << exc.what() << this->reset << std::endl;
    }
  } else {
    std::clog << this->reset << std::endl;
  }
}

void Logger::info(const std::string &msg,
                  const std::source_location location) const {
  if (this->noOutput) {
    return;
  }
  auto fullMsg =
      std::format("{}[ INFO ] {} - {}:{}: {} {}", this->blue, this->logmodule,
                  location.file_name(), location.line(), msg, this->reset);
  std::clog << fullMsg << std::endl;
}

void Logger::debug(const std::string &msg,
                   const std::source_location location) const {
  auto fullMsg =
      std::format("{}[ DEBUG ] {} - {}:{}: {} {}", this->green, this->logmodule,
                  location.file_name(), location.line(), msg, this->reset);
  std::clog << fullMsg << std::endl;
}

void Logger::warn(const std::string &msg,
                  const std::source_location location) const {
  auto fullMsg =
      std::format("{}[ WARN ] {} - {}:{}: {} {}", this->yellow, this->logmodule,
                  location.file_name(), location.line(), msg, this->reset);
  std::clog << fullMsg << std::endl;
}
