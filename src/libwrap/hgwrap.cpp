#include "log.hpp"
#include "polyfill.hpp"
#include "utils.hpp"
#include "wrap.hpp"

#include <cctype>
#include <filesystem>
#include <string>
#include <vector>

const static Logger LOG("wrap::HgWrap"); // NOLINT

bool HgWrap::setupDirectory(const std::filesystem::path &path,
                            const std::filesystem::path &packageFilesPath) {
  auto url = this->url;
  if (url.empty()) {
    this->errors.emplace_back("Missing URL");
    LOG.warn("URL is empty");
    return false;
  }
  if (this->revision.empty()) {
    this->errors.emplace_back("Missing revision");
    LOG.warn("Revision is empty");
    return false;
  }
  std::string rev = this->revision;
  if (this->directory->empty()) {
    this->errors.emplace_back("Missing directory");
    LOG.warn("Directory is empty");
    return false;
  }
  auto targetDirectory = this->directory.value();
  std::string const fullPath =
      std::format("{}/{}", path.generic_string(), targetDirectory);
  auto result =
      launchProcess("hg", std::vector<std::string>{"clone", url, fullPath});
  if (result) {
    auto isTip = rev.size() == 3 &&
                 (std::tolower(rev[0]) == 't' && std::tolower(rev[1]) == 'i' &&
                  std::tolower(rev[2]) == 'p');
    if (isTip) {
      result = launchProcess(
          "hg", std::vector<std::string>{"--cwd", fullPath, "checkout", rev});
      if (!result) {
        this->errors.emplace_back("Failed to do hg checkout");
        return false;
      }
    }
    return this->postSetup(fullPath, packageFilesPath);
  }
  this->errors.emplace_back("Failed to do hg clone");
  return false;
}
