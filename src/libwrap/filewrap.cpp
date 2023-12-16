#include "ini.hpp"
#include "log.hpp"
#include "utils.hpp"
#include "wrap.hpp"

#include <filesystem>
#include <format>
#include <string>

static Logger LOG("wrap::FileWrap"); // NOLINT

FileWrap::FileWrap(ast::ini::Section *section) : Wrap(section) {
  if (auto val = section->findStringValue("source_url")) {
    this->sourceUrl = val.value();
  }
  if (auto val = section->findStringValue("source_fallback_url")) {
    this->sourceFallbackUrl = val.value();
  }
  if (auto val = section->findStringValue("source_filename")) {
    this->sourceFilename = val.value();
  }
  if (auto val = section->findStringValue("source_hash")) {
    this->sourceHash = val.value();
  }
  if (auto val = section->findStringValue("lead_directory_missing")) {
    this->leadDirectoryMissing = val == "true";
  }
}

void FileWrap::setupDirectory(std::filesystem::path path,
                              std::filesystem::path packageFilesPath) {
  auto url = this->sourceUrl;
  if (url.empty()) {
    LOG.warn("URL is empty");
    return;
  }
  auto hash = this->sourceHash;
  if (hash->empty()) {
    LOG.warn("Hash is empty");
    return;
  }
  auto sfn = this->sourceFilename;
  if (sfn->empty()) {
    LOG.warn("Sourcefilename is empty");
    return;
  }
  auto directory = this->directory;
  std::string targetDirectory;
  if (directory.has_value() && directory.value().empty()) {
    targetDirectory = directory.value();
  } else {
    auto lastDotPos = sfn->find_last_of('.');
    auto result =
        (lastDotPos != std::string::npos) ? sfn->substr(0, lastDotPos) : sfn;
    if (result->ends_with(".tar")) {
      lastDotPos = result->find_last_of('.');
      result = (lastDotPos != std::string::npos) ? result->substr(0, lastDotPos)
                                                 : result;
    }
    targetDirectory = result.value();
  }
  auto fullPath = std::format("{}/{}", path.c_str(), targetDirectory);
  auto archiveFileName = downloadWithFallback(url, this->sourceHash.value(),
                                              this->sourceFallbackUrl);
  if (!archiveFileName.has_value()) {
    LOG.warn("Unable to continue with setting up this wrap...");
    return;
  }
  auto workdir =
      this->leadDirectoryMissing ? std::filesystem::path{fullPath} : path;
  std::filesystem::create_directories(workdir);
  extractFile(archiveFileName.value(), workdir);
  this->postSetup(fullPath, packageFilesPath);
}
