#include "log.hpp"
#include "utils.hpp"

#include <cassert>
#include <filesystem>
#include <format>
#include <fstream>

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
  auto zipFileName = std::filesystem::path{randomFile()};
  auto logger = Logger("utilstest");
  logger.info(std::format("Output file is {}", zipFileName.c_str()));
  auto result = downloadFile(
      "https://github.com/JCWasmx86/Swift-MesonLSP/archive/refs/heads/main.zip",
      zipFileName);
  assert(result);
  auto directoryName = std::filesystem::path{randomFile()};
  logger.info(std::format("Output directory is {}", directoryName.c_str()));
  std::filesystem::create_directory(directoryName);
  result = extractFile(zipFileName, directoryName);
  assert(result);
  auto mustExist =
      directoryName / "Swift-MesonLSP-main/Benchmarks/extract_git_data.sh";
  assert(std::filesystem::exists(mustExist));
  auto mustFailFilename = std::filesystem::path{randomFile()};
  result =
      downloadFile("lnfvwoefvnwefvwvipwnefv2efvpov2nvov", mustFailFilename);
  assert(!result);
  assert(!std::filesystem::exists(mustFailFilename));
  testMergingDirectories(logger);
}
