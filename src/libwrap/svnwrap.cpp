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
    this->errors.emplace_back("Missing URL");
    return false;
  }
  auto rev = this->revision.empty() ? "HEAD" : this->revision;
  if (this->directory->empty()) {
    LOG.warn("Directory is empty");
    this->errors.emplace_back("Missing directory");
    return false;
  }
  auto targetDirectory = this->directory.value();
  std::string const fullPath =
      std::format("{}/{}", path.generic_string(), targetDirectory);
  auto result = launchProcess(
      "svn", std::vector<std::string>{"checkout", "--non-interactive",
                                      "--trust-server-cert-failures=unknown-ca,"
                                      "cn-mismatch,expired,not-yet-valid,other",
                                      "-r", rev, url, fullPath});
  if (!result) {
    this->errors.emplace_back("Failed to do svn checkout");
    return false;
  }
  return this->postSetup(fullPath, packageFilesPath);
}
