#include "log.hpp"
#include "utils.hpp"
#include "wrap.hpp"

#include <filesystem>
#include <format>
#include <string>
#include <vector>

const static Logger LOG("wrap::SvnWrap"); // NOLINT

bool SvnWrap::setupDirectory(std::filesystem::path path,
                             std::filesystem::path packageFilesPath) {
  auto url = this->url;
  if (url.empty()) {
    LOG.warn("URL is empty");
    return false;
  }
  auto rev = this->revision.empty() ? "HEAD" : this->revision;
  if (this->directory->empty()) {
    LOG.warn("Directory is empty");
    return false;
  }
  auto targetDirectory = this->directory.value();
  std::string const fullPath =
      std::format("{}/{}", path.c_str(), targetDirectory);
  auto result = launchProcess(
      "svn", std::vector<std::string>{"checkout", "-r", rev, url, fullPath});
  if (!result) {
    return false;
  }
  return this->postSetup(fullPath, packageFilesPath);
}
