#include "log.hpp"
#include "utils.hpp"
#include <cassert>
#include <cstdio>
#include <filesystem>
#include <format>
#include <fstream>
#include <iostream>

void testMergingDirectories(Logger logger) {
  auto workDir = std::filesystem::path{randomFile()};
  auto inputDir = workDir / "input";
  auto outputDir = workDir / "output";
  logger.info(std::format("Workdir is {}", workDir.c_str()));
  std::filesystem::create_directories(inputDir);
  std::filesystem::create_directories(outputDir);
  std::filesystem::create_directories(inputDir / "i1");
  std::ofstream(inputDir / "i1/a.txt").put('a');
  std::filesystem::create_directories(outputDir / "i1");
  std::filesystem::create_directories(inputDir / "i2");
  std::ofstream(outputDir / "i1/a.txt").put('b');
  mergeDirectories(inputDir, outputDir);
  assert(std::filesystem::exists(outputDir / "i2"));
  assert('a' == std::ifstream(outputDir / "i1/a.txt").get());
}
int main(int argc, char **argv) {
  auto zip_file_name = std::filesystem::path{randomFile()};
  auto logger = Logger("utilstest");
  logger.info(std::format("Output file is {}", zip_file_name.c_str()));
  auto result = downloadFile(
      "https://github.com/JCWasmx86/Swift-MesonLSP/archive/refs/heads/main.zip",
      zip_file_name);
  assert(result);
  auto directory_name = std::filesystem::path{randomFile()};
  logger.info(std::format("Output directory is {}", directory_name.c_str()));
  std::filesystem::create_directory(directory_name);
  result = extractFile(zip_file_name, directory_name);
  assert(result);
  auto must_exist =
      directory_name / "Swift-MesonLSP-main/Benchmarks/extract_git_data.sh";
  assert(std::filesystem::exists(must_exist));
  auto must_fail_file_name = std::filesystem::path{randomFile()};
  result =
      downloadFile("lnfvwoefvnwefvwvipwnefv2efvpov2nvov", must_fail_file_name);
  assert(!result);
  assert(!std::filesystem::exists(must_fail_file_name));
  testMergingDirectories(logger);
}
