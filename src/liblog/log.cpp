#include "log.hpp"

#include <exception>
#include <iostream>
#include <source_location>
#include <string>
#include <unistd.h>
#include <utility>

Logger::Logger(std::string module) : module(std::move(module)) {
  if (isatty(STDERR_FILENO) != 0) {
    this->blue = "\033[96m";
    this->red = "\033[91m";
    this->yellow = "\033[93m";
    this->reset = "\033[0m";
  } else {
    this->blue = "";
    this->red = "";
    this->yellow = "";
    this->reset = "";
  }
}

void Logger::error(const std::string &msg,
                   const std::source_location location) {
  std::clog << this->red << "[ ERROR ] " << this->module << "-"
            << location.file_name() << ":" << location.line() << ": " << msg
            << std::endl;
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

void Logger::info(const std::string &msg, const std::source_location location) {
  std::clog << this->blue << "[ INFO ] " << this->module << "-"
            << location.file_name() << ":" << location.line() << ": " << msg
            << this->reset << std::endl;
}

void Logger::warn(const std::string &msg, const std::source_location location) {
  std::clog << this->yellow << "[ WARN ] " << this->module << "-"
            << location.file_name() << ":" << location.line() << ": " << msg
            << this->reset << std::endl;
}
