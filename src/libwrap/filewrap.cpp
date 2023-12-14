#include "ini.hpp"
#include "utils.hpp"
#include "wrap.hpp"
#include <filesystem>
#include <format>

FileWrap::FileWrap(ast::ini::Section *section) : Wrap(section) {
  if (auto val = section->find_string_value("source_url")) {
    this->sourceUrl = val.value();
  }
  if (auto val = section->find_string_value("source_fallback_url")) {
    this->sourceFallbackUrl = val.value();
  }
  if (auto val = section->find_string_value("source_filename")) {
    this->sourceFilename = val.value();
  }
  if (auto val = section->find_string_value("source_hash")) {
    this->sourceHash = val.value();
  }
  if (auto val = section->find_string_value("lead_directory_missing")) {
    this->leadDirectoryMissing = val == "true";
  }
}

void FileWrap::setupDirectory(std::filesystem::path path,
                              std::filesystem::path packageFilesPath) {
  auto url = this->sourceUrl;
  if (url.empty()) {
    return;
  }
  auto hash = this->sourceHash;
  if (hash->empty()) {
    return;
  }
  auto sfn = this->sourceFilename;
  if (sfn->empty()) {
    return;
  }
  auto directory = this->directory;
  std::string targetDirectory;
  if (directory.has_value() && directory.value().empty()) {
    targetDirectory = directory.value();
  } else {
    size_t lastDotPos = sfn->find_last_of('.');
    auto result =
        (lastDotPos != std::string::npos) ? sfn->substr(0, lastDotPos) : sfn;
    targetDirectory = result.value();
  }
  auto fullPath = std::format("{}/{}", path.c_str(), targetDirectory);
  // TODO: Caching
  auto archiveFileName = std::filesystem::path{randomFile()};
  downloadFile(url, archiveFileName);
  auto wd = this->leadDirectoryMissing ? std::filesystem::path{fullPath} : path;
  std::filesystem::create_directories(wd);
  extractFile(archiveFileName, wd);
  this->postSetup(fullPath, packageFilesPath);
}
