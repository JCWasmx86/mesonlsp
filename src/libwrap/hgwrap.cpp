#include "log.hpp"
#include "utils.hpp"
#include "wrap.hpp"

#include <cctype>
#include <filesystem>
#include <format>
#include <string>
#include <vector>

static Logger LOG("wrap::HgWrap"); // NOLINT

bool HgWrap::setupDirectory(std::filesystem::path path,
                            std::filesystem::path packageFilesPath) {
  auto url = this->url;
  if (url.empty()) {
    LOG.warn("URL is empty");
    return false;
  }
  if (this->revision.empty()) {
    LOG.warn("Revision is empty");
    return false;
  }
  std::string rev = this->revision;
  if (this->directory->empty()) {
    LOG.warn("Directory is empty");
    return false;
  }
  auto targetDirectory = this->directory.value();
  std::string const fullPath = std::format("{}/{}", path.c_str(), targetDirectory);
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
        return false;
      }
    }
    return this->postSetup(fullPath, packageFilesPath);
  }
  return false;
}
