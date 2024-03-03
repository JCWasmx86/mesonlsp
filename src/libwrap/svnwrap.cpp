#include "log.hpp"
#include "polyfill.hpp"
#include "utils.hpp"
#include "wrap.hpp"

#include <filesystem>
#include <string>
#include <vector>

const static Logger LOG("wrap::SvnWrap"); // NOLINT

bool SvnWrap::setupDirectory(const std::filesystem::path &path,
                             const std::filesystem::path &packageFilesPath) {
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
      std::format("{}/{}", path.generic_string(), targetDirectory);
  auto result = launchProcess(
      "svn", std::vector<std::string>{"checkout", "-r", "--non-interactive",
                                      rev, url, fullPath});
  if (!result) {
    return false;
  }
  return this->postSetup(fullPath, packageFilesPath);
}
