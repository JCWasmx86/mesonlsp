#include "lintingconfig.hpp"
#include "polyfill.hpp"

#include <cstdlib>
#include <cstring>
#include <exception>
#include <filesystem>
#include <iostream>
#include <sys/types.h>
#ifdef USE_MIMALLOC
#include <mimalloc.h>
#endif
#ifdef USE_JEMALLOC
#include <jemalloc/jemalloc.h>
#endif

void printHelp() {
  std::cerr << "Usage: mesonlint [<options>] [<path>]" << std::endl
            << std::endl;
  std::cerr << "ARGUMENTS:" << std::endl;
  std::cerr << "  <path>\tPath to parse" << std::endl << std::endl;
  std::cerr << "OPTIONS:" << std::endl;
  std::cerr << "--version    \t\t\tPrint version" << std::endl;
  std::cerr << "--help       \t\t\tPrint this help" << std::endl;
}

void printVersion() {
  std::cout << "mesonlint version: " << VERSION << std::endl;
  std::cout << "Using C compiler:       " << CC_VERSION << std::endl;
  std::cout << "Using C++ compiler:     " << CXX_VERSION << std::endl;
  std::cout << "Linker:                 " << LINKER_ID << std::endl;
#ifdef USE_MIMALLOC
  std::cout << "Using mimalloc: " << MI_MALLOC_VERSION << std::endl;
#endif
#ifdef USE_JEMALLOC
  std::cout << "Using jemalloc: " << JEMALLOC_VERSION << std::endl;
#endif
}

int main(int argc, char **argv) {
#ifndef _WIN32
  std::locale::global(std::locale(""));
#else
  try {
    std::locale::global(std::locale(""));
  } catch (...) {
    // Hack to avoid:
    // terminate called after throwing an instance of 'std::runtime_error'
    //   what():  locale::facet::_S_create_c_locale name not valid
    putenv("LANG=C");
    putenv("LC_ALL=C");
    std::locale::global(std::locale(""));
  }
#endif
  bool help = false;
  bool version = false;
  bool error = false;
  std::string path;
  uint numPaths = 0;
  for (int i = 1; i < argc; i++) {
    if (strcmp("--help", argv[i]) == 0) {
      help = true;
      continue;
    }
    if (strcmp("--version", argv[i]) == 0) {
      version = true;
      continue;
    }
    if (strncmp(argv[i], "--", 2) == 0) {
      std::cerr << "Unknown option: " << argv[i] << std::endl;
      error = true;
      continue;
    }
    numPaths++;
    path = argv[i];
  }
  if (error || help) {
    printHelp();
    return error ? EXIT_FAILURE : EXIT_SUCCESS;
  }
  if (version) {
    printVersion();
    return EXIT_SUCCESS;
  }
  if (numPaths > 1) {
    std::cerr << "Too many paths given." << std::endl;
    return EXIT_FAILURE;
  }
  std::filesystem::path root = path;
  if (!std::filesystem::exists(root)) {
    std::cerr << std::format("{} does not exist", root.generic_string())
              << std::endl;
    return EXIT_FAILURE;
  }
  if (!std::filesystem::exists(root / "meson.build")) {
    std::cerr << std::format("Failed to find meson.build file in {}",
                             root.generic_string())
              << std::endl;
    return EXIT_FAILURE;
  }
  MesonLintConfig config;
  try {
    config.load(root);
  } catch (const std::exception &exc) {
    std::cerr << std::format("Failed to load config: {}", exc.what())
              << std::endl;
    return EXIT_FAILURE;
  }
}
