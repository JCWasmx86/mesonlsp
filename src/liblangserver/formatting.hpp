#pragma once
#include <filesystem>
#include <string>

struct workspace;

std::string formatFile(struct workspace *wk, const std::filesystem::path &path,
                       const std::string &toFormat,
                       const std::filesystem::path &configFile);
