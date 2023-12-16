#include "analysisoptions.hpp"
#include "libwrap/wrap.hpp"
#include "mesontree.hpp"

#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <iostream>
#include <node.hpp>
#include <sourcefile.hpp>
#include <string>
#include <tree_sitter/api.h>
#include <vector>

extern "C" TSLanguage *tree_sitter_meson(); // NOLINT

void printHelp() {
  std::cerr << "Usage: Swift-MesonLSP [<options>] [<paths> ...]" << std::endl
            << std::endl;
  std::cerr << "ARGUMENTS:" << std::endl;
  std::cerr << "  <paths>\tPath to parse" << std::endl << std::endl;
  std::cerr << "OPTIONS:" << std::endl;
  std::cerr
      << "--path <path>\t\t\tPath to parse 100x times (default: ./meson.build)"
      << std::endl;
  std::cerr << "--lsp        \t\t\tStart language server using stdio"
            << std::endl;
  std::cerr << "--wrap <wrapFile>\t\tExtract and parse this wrap file"
            << std::endl;
  std::cerr << "--wrap-output <dir>\t\tSet the directory into that the given "
               "wraps should be extracted."
            << std::endl;
  std::cerr << "--wrap-package-files <dir>\tSet the location of the package "
               "files containing auxiliary files"
            << std::endl;
  std::cerr
      << "--full \t\t\tFully setup and check a project (Includes subprojects)"
      << std::endl;
  std::cerr << "--version    \t\t\tPrint version" << std::endl;
  std::cerr << "--help       \t\t\tPrint this help" << std::endl;
}

void printVersion() { std::cout << VERSION << std::endl; }

void startLanguageServer() {}

int parseWraps(std::vector<std::string> wraps, std::string output,
               std::string packageFiles) {
  if (output.empty()) {
    std::cerr << "No output directory given. Use --wrap-output" << std::endl;
    return EXIT_FAILURE;
  }
  if (packageFiles.empty()) {
    std::cerr << "No package files directory given. Use --wrap-package-files"
              << std::endl;
    return EXIT_FAILURE;
  }
  auto outputFs = std::filesystem::path(output);
  std::filesystem::create_directories(outputFs);
  auto packageFilesFs = std::filesystem::path(packageFiles);
  if (!std::filesystem::exists(packageFilesFs)) {
    std::cerr << output << " does not exist" << std::endl;
    return EXIT_FAILURE;
  }
  auto error = false;
  for (const auto &wrap : wraps) {
    auto wrapFs = std::filesystem::path(wrap);
    if (!std::filesystem::exists(wrapFs)) {
      std::cerr << wrapFs << " does not exist" << std::endl;
      error = true;
      continue;
    }
    auto ptr = parseWrap(wrapFs);
    if (!ptr || !ptr->serializedWrap) {
      continue;
    }
    ptr->serializedWrap->setupDirectory(outputFs, packageFilesFs);
  }
  return error ? EXIT_FAILURE : EXIT_SUCCESS;
}

int main(int argc, char **argv) {
  std::string path = "./meson.build";
  std::vector<std::string> paths;
  std::vector<std::string> wraps;
  std::string wrapOutput;
  std::string wrapPackageFiles;
  bool lsp = false;
  bool help = false;
  bool version = false;
  bool error = false;
  bool full = false;
  for (int i = 1; i < argc; i++) {
    if (strcmp("--lsp", argv[i]) == 0) {
      lsp = true;
      continue;
    }
    if (strcmp("--full", argv[i]) == 0) {
      full = true;
      continue;
    }
    if (strcmp("--stdio", argv[i]) == 0) {
      continue;
    }
    if (strcmp("--help", argv[i]) == 0) {
      help = true;
      continue;
    }
    if (strcmp("--version", argv[i]) == 0) {
      version = true;
      continue;
    }
    if (strcmp("--path", argv[i]) == 0) {
      if (i + 1 == argc) {
        std::cerr << "Error: Missing value for --path <path>" << std::endl;
        error = true;
        break;
      }
      path = std::string(argv[i + 1]);
      i++;
      continue;
    }
    if (strcmp("--wrap", argv[i]) == 0) {
      if (i + 1 == argc) {
        std::cerr << "Error: Missing value for --wrap <wrap-file>" << std::endl;
        error = true;
        break;
      }
      wraps.emplace_back(std::string(argv[i + 1]));
      i++;
      continue;
    }
    if (strcmp("--wrap-output", argv[i]) == 0) {
      if (i + 1 == argc) {
        std::cerr << "Error: Missing value for --wrap-output <directory>"
                  << std::endl;
        error = true;
        break;
      }
      wrapOutput = std::string(argv[i + 1]);
      i++;
      continue;
    }
    if (strcmp("--wrap-package-files", argv[i]) == 0) {
      if (i + 1 == argc) {
        std::cerr << "Error: Missing value for --wrap-package-files <directory>"
                  << std::endl;
        error = true;
        break;
      }
      wrapPackageFiles = std::string(argv[i + 1]);
      i++;
      continue;
    }
    if (strncmp(argv[i], "--", 2) == 0) {
      std::cerr << "Unknown option: " << argv[i] << std::endl;
      error = true;
      continue;
    }
    paths.emplace_back(argv[i]);
  }
  if (error || help) {
    printHelp();
    return error ? EXIT_FAILURE : EXIT_SUCCESS;
  }
  if (version) {
    printVersion();
    return EXIT_SUCCESS;
  }
  if (lsp) {
    startLanguageServer();
    return EXIT_SUCCESS;
  }
  if (!wraps.empty()) {
    return parseWraps(wraps, wrapOutput, wrapPackageFiles);
  }
  if (paths.empty()) {
    auto parent = std::filesystem::absolute(path).parent_path();
    MesonTree tree(parent);
    AnalysisOptions opts(false, false, false, false, false, false, false);
    if (full) {
      tree.fullParse(opts);
    } else {
      tree.partialParse(opts);
    }
    return 0;
  }
}
