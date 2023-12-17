#include "subprojectstate.hpp"

#include "log.hpp"
#include "subproject.hpp"
#include "utils.hpp"

#include <chrono>
#include <filesystem>
#include <format>
#include <memory>
#include <string>

Logger LOG("analyze::subprojectstate"); // NOLINT

void SubprojectState::findSubprojects() {
  auto subprojectsDir = std::filesystem::absolute(this->root) / "subprojects";
  if (!std::filesystem::exists(subprojectsDir) ||
      !std::filesystem::is_directory(subprojectsDir)) {
    return;
  }
  auto extractionDir = cacheDir() / "wrapsWorkspace";
  std::filesystem::create_directories(extractionDir);
  auto packageFiles = subprojectsDir / "packagefiles";
  for (const auto &entry :
       std::filesystem::directory_iterator(subprojectsDir)) {
    auto child = std::filesystem::absolute(entry.path());
    auto matchesWrap =
        std::filesystem::is_regular_file(child) && child.extension() == ".wrap";
    if (!matchesWrap) {
      continue;
    }
    auto ftime = std::filesystem::last_write_time(child);
    const auto systemTime =
        std::chrono::clock_cast<std::chrono::system_clock>(ftime);
    const auto time = std::chrono::system_clock::to_time_t(systemTime);
    auto identifier = std::format("{}-{}", hash(child), time);
    LOG.info(std::format("{}: Identifier is: {}", child.filename().c_str(),
                         identifier));
    auto wrapBaseDir = extractionDir / child.filename() / identifier;
    LOG.info(std::format("Extracting wrap to {}", wrapBaseDir.c_str()));
    auto checkFile = wrapBaseDir / ".fullysetup";
    auto subprojectName = child.stem().string();
    if (std::filesystem::exists(checkFile)) {
      LOG.info("Wrap is already setup!");
      this->subprojects.emplace_back(
          std::make_shared<CachedSubproject>(subprojectName, wrapBaseDir));
    } else {
      if (std::filesystem::exists(wrapBaseDir)) {
        LOG.warn(
            std::format("{} exists, but is not fully setup => Reattempting",
                        wrapBaseDir.c_str()));
        std::filesystem::remove_all(wrapBaseDir);
      }
      LOG.info(std::format("Installing {} into {}", child.filename().string(),
                           wrapBaseDir.string()));
      std::filesystem::create_directories(wrapBaseDir);
      this->subprojects.emplace_back(std::make_shared<WrapSubproject>(
          subprojectName, child, packageFiles, wrapBaseDir));
    }
  }
  for (const auto &entry :
       std::filesystem::directory_iterator(subprojectsDir)) {
    auto child = std::filesystem::absolute(entry.path());
    if (!std::filesystem::is_directory(child)) {
      continue;
    }
    auto filename = child.filename();
    if (filename == "packagefiles" || filename == "packagecache" ||
        std::filesystem::exists(child / ".meson-subproject-wrap-hash.txt")) {
      continue;
    }
    for (const auto &subproject : this->subprojects) {
      if (subproject->name == filename) {
        LOG.info(std::format("Found already registered subproject: {}",
                             subproject->name));
        goto cont;
      }
    }
    LOG.info(std::format("Found folder based subproject {}", filename.c_str()));
    this->subprojects.emplace_back(
        std::make_shared<FolderSubproject>(filename, child));
  cont:
    continue;
  }
}

void SubprojectState::initSubprojects() {
  for (const auto &subproject : this->subprojects) {
    subproject->init();
  }
}

void SubprojectState::updateSubprojects() {
  for (const auto &subproject : this->subprojects) {
    subproject->update();
  }
}
