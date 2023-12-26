#pragma once

#include "sha-256.h"

#include <algorithm>
#include <cassert>
#include <cctype>
#include <cstddef>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <optional>
#include <sstream>
#include <string>
#include <vector>

bool downloadFile(std::string url, const std::filesystem::path &output);
bool extractFile(const std::filesystem::path &archivePath,
                 const std::filesystem::path &outputDirectory);
bool launchProcess(const std::string &executable,
                   const std::vector<std::string> &args);
std::optional<std::filesystem::path> cachedDownload(const std::string &url);
std::optional<std::filesystem::path>
downloadWithFallback(std::string url, const std::string &hash,
                     std::optional<std::string> fallbackUrl);
std::string errno2string();
void mergeDirectories(const std::filesystem::path &sourcePath,
                      const std::filesystem::path &destinationPath);
std::filesystem::path cacheDir();
std::string readFile(std::filesystem::path &path);

static inline std::string vectorToString(const std::vector<std::string> &vec) {
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

static inline std::string hash(const void *data, const size_t len) {
  uint8_t hash[SIZE_OF_SHA_256_HASH] = {0};
  calc_sha_256(hash, data, len);
  std::stringstream sss;

  sss << std::hex << std::setfill('0');
  for (unsigned char byte : hash) {
    sss << std::hex << std::setw(2) << static_cast<int>(byte);
  }
  return sss.str();
}

static inline std::string hash(const std::string &key) {
  return hash(key.c_str(), key.size());
}

static inline std::string hash(const std::filesystem::path &path) {
  std::ifstream file(path, std::ios::binary | std::ios::ate);
  auto fileSize = file.tellg();
  file.seekg(0, std::ios::beg);
  assert(fileSize > 0);
  std::vector<uint8_t> buffer(fileSize);
  file.read(reinterpret_cast<char *>(buffer.data()), fileSize);
  file.close();
  return hash(buffer.data(), fileSize);
}

static inline void ltrim(std::string &str) {
  str.erase(str.begin(),
            std::find_if(str.begin(), str.end(), [](unsigned char chr) {
              return std::isspace(chr) == 0;
            }));
}

static inline void rtrim(std::string &str) {
  str.erase(
      std::find_if(str.rbegin(), str.rend(),
                   [](unsigned char chr) { return std::isspace(chr) == 0; })
          .base(),
      str.end());
}

static inline void trim(std::string &str) {
  rtrim(str);
  ltrim(str);
}

// https://stackoverflow.com/a/56891830
inline std::string replace(std::string &str, const std::string &substr1,
                           const std::string &substr2) {
  for (size_t index = str.find(substr1, 0);
       index != std::string::npos && (substr1.length() != 0U);
       index = str.find(substr1, index + substr2.length())) {
    str.replace(index, substr1.length(), substr2);
  }
  return str;
}

inline std::vector<std::string> split(const std::string &str,
                                      const std::string &delim) {
  std::vector<std::string> result;
  size_t start = 0;

  for (size_t found = str.find(delim); found != std::string::npos;
       found = str.find(delim, start)) {
    result.emplace_back(str.begin() + (long)start, str.begin() + (long)found);
    start = found + delim.size();
  }
  if (start != str.size()) {
    result.emplace_back(str.begin() + (long)start, str.end());
  }
  return result;
}

template <typename Container>
inline std::string joinStrings(const Container &cont, const char chr) {
  std::stringstream strStream;
  auto iter = std::begin(cont);
  if (iter != std::end(cont)) {
    strStream << *iter;
    ++iter;
  }
  for (; iter != std::end(cont); ++iter) {
    strStream << chr << *iter;
  }
  return strStream.str();
}
