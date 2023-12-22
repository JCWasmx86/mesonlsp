#include "utils.hpp"

#include <filesystem>
#include <format>
#include <fstream>
#include <gtest/gtest.h>
#include <uuid/uuid.h>

std::string randomFile() {
  auto *tmpdir = getenv("TMPDIR"); // NOLINT
  if (tmpdir == nullptr) {
    tmpdir = (char *)"/tmp";
  }
  uuid_t filename;
  uuid_generate(filename);
  char out[UUID_STR_LEN + 1] = {0};
  uuid_unparse(filename, out);
  return std::format("{}/{}", tmpdir, out);
}

TEST(UtilsTest, testMergingDirectories) {
  auto workDir = std::filesystem::path{randomFile()};
  auto inputDir = workDir / "input";
  auto outputDir = workDir / "output";
  std::filesystem::create_directories(inputDir);
  std::filesystem::create_directories(outputDir);
  std::filesystem::create_directories(inputDir / "i1");
  std::ofstream(inputDir / "i1/a.txt").put('a');
  std::filesystem::create_directories(outputDir / "i1");
  std::filesystem::create_directories(inputDir / "i2");
  std::ofstream(outputDir / "i1/a.txt").put('b');
  mergeDirectories(inputDir, outputDir);
  ASSERT_TRUE(std::filesystem::exists(outputDir / "i2"));
  ASSERT_EQ('a', std::ifstream(outputDir / "i1/a.txt").get());
}

TEST(UtilsTest, testDownloadAndExtraction) {
  auto zipFileName = std::filesystem::path{randomFile()};
  auto result = downloadFile(
      "https://github.com/JCWasmx86/Swift-MesonLSP/archive/refs/heads/main.zip",
      zipFileName);
  ASSERT_TRUE(result);
  auto directoryName = std::filesystem::path{randomFile()};
  std::filesystem::create_directory(directoryName);
  result = extractFile(zipFileName, directoryName);
  ASSERT_TRUE(result);
  auto mustExist =
      directoryName / "Swift-MesonLSP-main/Benchmarks/extract_git_data.sh";
  ASSERT_TRUE(std::filesystem::exists(mustExist));
  auto mustFailFilename = std::filesystem::path{randomFile()};
  result =
      downloadFile("lnfvwoefvnwefvwvipwnefv2efvpov2nvov", mustFailFilename);
  ASSERT_FALSE(result);
  ASSERT_FALSE(std::filesystem::exists(mustFailFilename));
}

int main(int argc, char **argv) {
  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
