#include "log.hpp"
#include <iostream>
#include <string>

Logger::Logger(std::string module) { this->module = module; }

void Logger::error(std::string msg, const std::source_location location) {
  std::clog << "\033[91m[ ERROR ] " << this->module << "-"
            << location.file_name() << ":" << location.line() << ": " << msg
            << "\033[0m" << std::endl;
}

void Logger::info(std::string msg, const std::source_location location) {
  std::clog << "\033[96m[ INFO ] " << this->module << "-"
            << location.file_name() << ":" << location.line() << ": " << msg
            << "\033[0m" << std::endl;
}

void Logger::warn(std::string msg, const std::source_location location) {
  std::clog << "\033[93m[ WARN ] " << this->module << "-"
            << location.file_name() << ":" << location.line() << ": " << msg
            << "\033[0m" << std::endl;
}
