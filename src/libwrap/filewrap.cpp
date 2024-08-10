#include "ini.hpp"
#include "log.hpp"
#include "polyfill.hpp"
#include "utils.hpp"
#include "wrap.hpp"

#include <filesystem>
#include <format>
#include <string>

const static Logger LOG("wrap::FileWrap"); // NOLINT

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

bool FileWrap::setupDirectory(const std::filesystem::path &path,
                              const std::filesystem::path &packageFilesPath) {
  auto sfn = this->sourceFilename;
  if (sfn->empty()) {
    LOG.warn("Sourcefilename is empty");
    this->errors.push_back(std::format("Missing source_filename"));
    return false;
  }
  auto directory = this->directory;
  std::string targetDirectory;
  if (directory.has_value() && !directory.value().empty()) {
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
  const std::filesystem::path fullPath =
      std::format("{}/{}", path.generic_string(), targetDirectory);
  auto workdir =
      this->leadDirectoryMissing ? std::filesystem::path{fullPath} : path;
  auto url = this->sourceUrl;
  if (url.empty()) {
    LOG.info("URL is empty");
    auto subprojectsPath = packageFilesPath.parent_path();
    auto maybeDir = subprojectsPath / sfn.value();
    if (std::filesystem::exists(maybeDir)) {
      LOG.info(
          "But we found a matching directory in subprojects/. Setting up in " +
          workdir.generic_string());
      std::filesystem::create_directories(workdir / sfn.value());
      mergeDirectories(maybeDir, workdir / sfn.value());
      return this->postSetup(fullPath, packageFilesPath);
    }
    this->errors.push_back(std::format("Missing source_url"));
    return false;
  }
  std::filesystem::create_directories(workdir);
  auto hash = this->sourceHash;
  if (hash->empty()) {
    LOG.warn("Hash is empty");
    this->errors.push_back(std::format("Missing source_hash"));
    return false;
  }
  auto archiveFileName = downloadWithFallback(url, this->sourceHash.value(),
                                              this->sourceFallbackUrl);
  if (!archiveFileName.has_value()) {
    LOG.warn("Unable to continue with setting up this wrap...");
    this->errors.push_back(
        std::format("Failed to download {} (With fallback {})", url,
                    this->sourceFallbackUrl.value_or("None")));
    return false;
  }
  if (!extractFile(archiveFileName.value(), workdir)) {
    this->errors.emplace_back(std::format("Failed to extract {} to {}",
                                          archiveFileName->c_str(),
                                          workdir.c_str()));
    return false;
  }
  return this->postSetup(fullPath, packageFilesPath);
}
