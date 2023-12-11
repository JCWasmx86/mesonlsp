#pragma once

#include <filesystem>

bool download_file(std::string url, std::filesystem::path output);
bool extract_file(std::filesystem::path archive_path,
                  std::filesystem::path output_directory);
