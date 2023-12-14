#pragma once

#include <algorithm>
#include <cctype>
#include <filesystem>
#include <string>
#include <vector>

bool downloadFile(std::string url, std::filesystem::path output);
bool extractFile(std::filesystem::path archive_path,
                 std::filesystem::path output_directory);
bool launchProcess(const std::string &executable,
                   const std::vector<std::string> &args);
std::string errno2string();
std::string randomFile();
void mergeDirectories(std::filesystem::path sourcePath,
                      std::filesystem::path destinationPath);

inline std::string vectorToString(const std::vector<std::string> &vec) {
  std::stringstream output;
  output << '[';
  for (size_t i = 0; i < vec.size(); ++i) {
    if (i > 0) {
      output << ',';
    }
    output << vec[i];
  }
  output << ']';
  return output.str();
}
static inline void ltrim(std::string &str) {
  str.erase(str.begin(),
            std::find_if(str.begin(), str.end(),
                         [](unsigned char chr) { return !std::isspace(chr); }));
}

static inline void rtrim(std::string &str) {
  str.erase(std::find_if(str.rbegin(), str.rend(),
                         [](unsigned char chr) { return !std::isspace(chr); })
                .base(),
            str.end());
}

static inline void trim(std::string &str) {
  rtrim(str);
  ltrim(str);
}
