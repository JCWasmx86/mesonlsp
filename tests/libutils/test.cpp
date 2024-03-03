#include "polyfill.hpp"
#include "utils.hpp"

#include <array>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <gtest/gtest.h>
#include <string>
#ifndef _WIN32
#include <uuid/uuid.h>
#else
#include <chrono>
#endif
#include <vector>

// See https://github.com/netdata/netdata/pull/10313
#ifndef UUID_STR_LEN
#define UUID_STR_LEN 37
#endif

std::string randomFile() {
  auto *tmpdir = getenv("TMPDIR"); // NOLINT
  std::filesystem::path realTempDir;
  if (tmpdir == nullptr) {
    realTempDir =
        (char *)std::filesystem::temp_directory_path().generic_string().c_str();
  } else {
    realTempDir = tmpdir;
  }
#ifndef _WIN32
  uuid_t filename;
  uuid_generate(filename);
  std::array<char, UUID_STR_LEN + 1> out;
  uuid_unparse(filename, out.data());
  return std::format("{}/{}", realTempDir.generic_string(), out.data());
#else
  const auto now = std::chrono::system_clock::now();
  return std::format("{}/{:%F%H%I%M}", realTempDir, now);
#endif
}

TEST(UtilsTest, testUpperCase) {
  std::string input = "foo123";
  ASSERT_EQ("FOO123", uppercase(input));
  input = "foo123ß";
  ASSERT_EQ("FOO123ß", uppercase(input));
  input = "foo123 ";
  ASSERT_EQ("FOO123 ", uppercase(input));
}

TEST(UtilsTest, testLowerCase) {
  std::string input = "FOO123";
  ASSERT_EQ("foo123", lowercase(input));
  input = "FOO123ß";
  ASSERT_EQ("foo123ß", lowercase(input));
  input = "FOO123 ";
  ASSERT_EQ("foo123 ", lowercase(input));
}

TEST(UtilsTest, testJoinStrings) {
  ASSERT_EQ(
      "foo,bar,baz,qux",
      joinStrings(std::vector<std::string>{"foo", "bar", "baz", "qux"}, ','));
}

TEST(UtilsTest, testTrim) {
  std::string input = "  foo \n";
  trim(input);
  ASSERT_EQ(input, "foo");
}

TEST(UtilsTest, testReplace) {
  // https://github.com/openjdk/jdk/blob/faa9c6909dda635eb008b9dada6e06fca47c17d6/test/jdk/java/lang/String/LiteralReplace.java#L89
  // Except "" doesn't replace anything (E.g. {"abcdefgh", "", "_",
  // "_a_b_c_d_e_f_g_h_"} will fail)
  for (const auto &vec : std::vector<std::vector<std::string>>{
           {"aaa", "aa", "b", "ba"},
           {"abcdefgh", "def", "DEF", "abcDEFgh"},
           {"abcdefgh", "123", "DEF", "abcdefgh"},
           {"abcdefgh", "abcdefghi", "DEF", "abcdefgh"},
           {"abcdefghabc", "abc", "DEF", "DEFdefghDEF"},
           {"abcdefghdef", "def", "", "abcgh"},
           {"", "", "", ""},
           {"", "a", "b", ""},
           {"abcdefgh", "abcdefgh", "abcdefgh", "abcdefgh"},
           {"abcdefgh", "abcdefgh", "abcdefghi", "abcdefghi"},
           {"abcdefgh", "abcdefgh", "", ""},
           {"abcdabcd", "abcd", "", ""},
           {"aaaaaaaaa", "aa", "_X_", "_X__X__X__X_a"},
           {"aaaaaaaaa", "aa", "aaa", "aaaaaaaaaaaaa"},
           {"aaaaaaaaa", "aa", "aa", "aaaaaaaaa"},
           {"a.c.e.g.", ".", "-", "a-c-e-g-"},
       }) {
    auto input = vec[0];
    ASSERT_EQ(vec[3], replace(input, vec[1], vec[2]));
  }
}

TEST(UtilsTest, testSplit) {
  auto parts = split("foo||bar", "||");
  auto expected = std::vector<std::string>{"foo", "bar"};
  ASSERT_EQ(parts, expected);
  parts = split("foo||bar||", "||");
  expected = std::vector<std::string>{"foo", "bar"};
  ASSERT_EQ(parts, expected);
  parts = split("bar|foo", "||");
  expected = std::vector<std::string>{"bar|foo"};
  ASSERT_EQ(parts, expected);
}

TEST(UtilsTest, testHash) {
  ASSERT_EQ("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
            hash(std::string("abc")));
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
