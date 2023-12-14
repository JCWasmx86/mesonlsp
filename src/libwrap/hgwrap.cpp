#include "ini.hpp"
#include "log.hpp"
#include "utils.hpp"
#include "wrap.hpp"
#include <format>

Logger LOG("wrap::HgWrap"); // NOLINT

void HgWrap::setupDirectory(std::filesystem::path path,
                            std::filesystem::path packageFilesPath) {
  auto url = this->url;
  if (url.empty()) {
    LOG.warn("URL is empty");
    return;
  }
  if (this->revision.empty()) {
    LOG.warn("Revision is empty");
    return;
  }
  std::string rev = this->revision;
  if (this->directory->empty()) {
    LOG.warn("Directory is empty");
    return;
  }
  auto targetDirectory = this->directory.value();
  std::string fullPath = std::format("{}/{}", path.c_str(), targetDirectory);
  auto result =
      launchProcess("hg", std::vector<std::string>{"clone", url, fullPath});
  if (result) {
    auto is_tip = rev.size() == 3 &&
                  (std::tolower(rev[0]) == 't' && std::tolower(rev[1]) == 'i' &&
                   std::tolower(rev[2]) == 'p');
    if (is_tip) {
      result = launchProcess(
          "hg", std::vector<std::string>{"--cwd", fullPath, "checkout", rev});
    }
    this->postSetup(fullPath, packageFilesPath);
  }
}
