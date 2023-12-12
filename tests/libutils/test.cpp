#include "log.hpp"
#include "utils.hpp"
#include <cassert>
#include <cstdio>
#include <filesystem>
#include <format>
#include <iostream>

int main(int argc, char **argv) {
  auto zip_file_name = std::filesystem::path{random_file()};
  auto logger = Logger("utilstest");
  logger.info(std::format("Output file is {}", zip_file_name.c_str()));
  auto result = download_file(
      "https://github.com/JCWasmx86/Swift-MesonLSP/archive/refs/heads/main.zip",
      zip_file_name);
  assert(result);
  auto directory_name = std::filesystem::path{random_file()};
  logger.info(std::format("Output directory is {}", directory_name.c_str()));
  std::filesystem::create_directory(directory_name);
  result = extract_file(zip_file_name, directory_name);
  assert(result);
  auto must_exist =
      directory_name / "Swift-MesonLSP-main/Benchmarks/extract_git_data.sh";
  assert(std::filesystem::exists(must_exist));
  auto must_fail_file_name = std::filesystem::path{random_file()};
  result =
      download_file("lnfvwoefvnwefvwvipwnefv2efvpov2nvov", must_fail_file_name);
  assert(!result);
  assert(!std::filesystem::exists(must_fail_file_name));
}
