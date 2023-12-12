#include "ini.hpp"
#include "utils.hpp"
#include "wrap.hpp"
#include <format>

void SvnWrap::setupDirectory(std::filesystem::path path,
                             std::filesystem::path packageFilesPath) {
  auto url = this->url;
  if (url.empty()) {
    return;
  }
  auto rev = this->revision.empty() ? "HEAD" : this->revision;
  if (this->directory->empty()) {
    return;
  }
  auto targetDirectory = this->directory.value();
  std::string fullPath = std::format("{}/{}", path.c_str(), targetDirectory);
  auto result = launchProcess(
      "svn", std::vector<std::string>{"checkout", "-r", rev, url, fullPath});
}
