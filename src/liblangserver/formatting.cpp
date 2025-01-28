#include "log.hpp"

#include <cstring>
#include <filesystem>
#include <string>
extern "C" {
#define new fnew
#include <lang/fmt.h>
#include <log.h>
#include <platform/filesystem.h>
#include <platform/init.h>
#undef ast
#undef fmt
#undef new
}
#ifdef _WIN32
#include "polyfill.hpp"
#include "utils.hpp"

#include <random>
#endif
const static Logger LOG("formatting"); // NOLINT

std::string formatFile(const std::filesystem::path &path,
                       const std::string &toFormat,
                       const std::filesystem::path &configFile) {
#ifndef _WIN32
  const auto *labelPath = path.c_str();
#else
  const wchar_t *labelPathW = path.c_str();
  char *labelPath = (char *)calloc(path.generic_string().size() * 2, 1);
  // Should be use wcstombs_s?
  wcstombs(labelPath, labelPathW, path.generic_string().size() * 2);
#endif
  struct source src = {.label = labelPath,
                       .src = strdup(toFormat.data()),
                       .len = toFormat.size(),
                       .type = source_type_unknown};
#ifndef _WIN32
  char *formattedStr;
  size_t formattedSize;
  auto *output = open_memstream(&formattedStr, &formattedSize);
#else
  static std::random_device device;
  static std::mt19937 gen(device());
  std::uniform_real_distribution<double> dist(0, UINT32_MAX);

  auto tmpPath = std::filesystem::temp_directory_path() /
                 std::format("mesonlsp-muon-format-{}", dist(gen));
  auto *output = ::fopen(tmpPath.generic_string().data(), "wb");
#endif
  auto fmtRet =
      fmt(&src, output, configFile.generic_string().c_str(), false, true);
  if (!fmtRet) {
    (void)fclose(output);
    free((void *)src.src);
#ifndef _WIN32
    free(formattedStr);
#else
    free(labelPath);
#endif
    LOG.error("Failed to format");
    throw std::runtime_error("Failed to format");
  }
  (void)fflush(output);
  (void)fclose(output);
#ifndef _WIN32
  std::string const asString(static_cast<const char *>(formattedStr),
                             formattedSize);
  free(formattedStr);
#else
  auto asString = readFile(tmpPath);
  free(labelPath);
  while (!asString.empty() && asString.back() == '\0') {
    asString.pop_back();
  }
#endif
  fs_source_destroy(&src);
  return asString;
}
