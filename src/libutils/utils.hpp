#pragma once

#include <filesystem>
#include <string>
#include <vector>

bool download_file(std::string url, std::filesystem::path output);
bool extract_file(std::filesystem::path archive_path,
                  std::filesystem::path output_directory);
bool launchProcess(std::string file, std::vector<std::string> args);
std::string errno2string();
std::string random_file();
