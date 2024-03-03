#include "analysisoptions.hpp"
#include "log.hpp"
#include "mesontree.hpp"
#include "polyfill.hpp"
#include "typenamespace.hpp"

#include <cassert>
#include <chrono>
#include <cstring>
#include <filesystem>
#include <optional>
#include <string>
#include <system_error>
#include <vector>

int main(int argc, char **argv) {
  Logger const logger("partial-interpreter-tester");
  std::filesystem::path const toParse = argv[1];
  std::vector<std::string> haveToExist;
  std::optional<std::filesystem::path> optionsFile;
  haveToExist.reserve(argc - 2);
  for (int i = 2; i < argc; i++) {
    if (strcmp(argv[i], "--") == 0) {
      assert(i + 1 < argc);
      optionsFile = argv[i + 1];
      break;
    }
    haveToExist.emplace_back(argv[i]);
  }
#ifndef __APPLE__
  std::filesystem::path const parent(
      std::format("{}/partial-interpreter{:%F%H%I%M}",
                  std::filesystem::temp_directory_path().generic_string(),
                  std::chrono::system_clock::now()));
#else
  std::filesystem::path const parent(std::format(
      "/tmp/partial-interpreter{}", std::chrono::system_clock::now()));

#endif
  std::filesystem::create_directories(parent);
  TypeNamespace const ns;
  std::error_code err;
  logger.info(std::format("Copying {} -> {}", toParse.generic_string(),
                          (parent / "meson.build").generic_string()));
  std::filesystem::copy_file(toParse, parent / "meson.build",
                             std::filesystem::copy_options::overwrite_existing,
                             err);
  assert(err == std::errc{});
  if (optionsFile.has_value()) {
    logger.info(std::format("Copying {} -> {}", optionsFile->generic_string(),
                            (parent / "meson.options").generic_string()));
    std::filesystem::copy_file(
        optionsFile.value(), parent / "meson.options",
        std::filesystem::copy_options::overwrite_existing, err);
  }
  MesonTree tree(parent, ns);
  AnalysisOptions const opts(false, false, false, false, false, false, false);
  tree.partialParse(opts);
  const auto &metadata = tree.scope.variables;
  auto errors = 0;
  for (const auto &varname : haveToExist) {
    if (metadata.contains(varname)) {
      continue;
    }
    logger.error("Failed to find variable " + varname);
    errors++;
  }
  if (errors != 0) {
    logger.error(std::format("Unable to find {} variables", errors));
  }
  return static_cast<int>(errors != 0);
}
