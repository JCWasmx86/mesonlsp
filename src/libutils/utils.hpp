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

bool downloadFile(std::string url, std::filesystem::path output);
bool extractFile(std::filesystem::path archivePath,
                 std::filesystem::path outputDirectory);
bool launchProcess(const std::string &executable,
                   const std::vector<std::string> &args);
std::optional<std::filesystem::path> cachedDownload(std::string url);
std::optional<std::filesystem::path>
downloadWithFallback(std::string url, std::string hash,
                     std::optional<std::string> fallbackUrl);
std::string errno2string();
std::string randomFile();
void mergeDirectories(std::filesystem::path sourcePath,
                      std::filesystem::path destinationPath);
std::filesystem::path cacheDir();

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
