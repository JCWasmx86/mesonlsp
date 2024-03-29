#pragma once
#include <filesystem>
#include <string>

std::string formatFile(const std::filesystem::path &path,
                       const std::string &toFormat,
                       const std::filesystem::path &configFile);
