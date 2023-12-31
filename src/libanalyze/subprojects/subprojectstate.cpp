#include "subprojectstate.hpp"

#include "analysisoptions.hpp"
#include "log.hpp"
#include "subproject.hpp"
#include "typenamespace.hpp"
#include "utils.hpp"

#include <chrono>
#include <filesystem>
#include <format>
#include <memory>
#include <optional>
#include <string>

Logger LOG("analyze::subprojectstate"); // NOLINT

static std::string normalizeURLToFilePath(const std::string &url);

void SubprojectState::findSubprojects(bool downloadSubprojects) {
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
    auto identifierOpt = createIdentifierForWrap(child);
    if (!identifierOpt.has_value()) {
      LOG.info("Skipping redirect wrap: " + child.generic_string());
      continue;
    }
    auto identifier = identifierOpt.value();
    LOG.info(std::format("{}: Identifier is: {}", child.filename().c_str(),
                         identifier));
    auto wrapBaseDir = extractionDir / child.filename() / identifier;
    LOG.info(std::format("Extracting wrap to {}", wrapBaseDir.c_str()));
    auto checkFile = wrapBaseDir / ".fullysetup";
    auto subprojectName = child.stem().string();
    if (std::filesystem::exists(checkFile)) {
      LOG.info("Wrap is already setup!");
      this->subprojects.emplace_back(std::make_shared<CachedSubproject>(
          subprojectName, wrapBaseDir / guessTargetDirectoryFromWrap(child)));
    } else if (downloadSubprojects) {
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
    } else {
      LOG.warn(std::format(
          "Won't setup {}, as downloads etc. were disabled by the user!",
          child.generic_string()));
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

void SubprojectState::parseSubprojects(AnalysisOptions &options, int depth,
                                       const std::string &parentIdentifier,
                                       const TypeNamespace &ns,
                                       bool downloadSubprojects) {
  for (const auto &subproject : this->subprojects) {
    subproject->parse(options, depth, parentIdentifier, ns,
                      downloadSubprojects);
  }
}

std::optional<std::string>
createIdentifierForWrap(const std::filesystem::path &path) {
  std::ifstream file(path);
  std::string line;
  bool isFile = false;
  bool isGit = false;
  std::string url;
  std::string revision;
  if (!file.is_open()) {
    goto makeDefault;
  }
  while (std::getline(file, line)) {
    if (line.contains("wrap-file")) {
      isFile = true;
      continue;
    }
    if (line.contains("wrap-git")) {
      isGit = true;
      continue;
    }
    if (line.contains("wrap-redirect")) {
      return std::nullopt;
    }
    if (line.starts_with("url")) {
      size_t lookAhead = 4;
      while (lookAhead < line.size() - 1) {
        if (line[lookAhead] == ' ' || line[lookAhead] == '=') {
          lookAhead++;
          continue;
        }
        break;
      }
      url = line.substr(lookAhead);
      continue;
    }
    if (line.starts_with("source_url")) {
      size_t lookAhead = sizeof("source_url") + 1;
      while (lookAhead < line.size() - 1) {
        if (line[lookAhead] == ' ' || line[lookAhead] == '=') {
          lookAhead++;
          continue;
        }
        break;
      }
      url = line.substr(lookAhead);
      continue;
    }
    if (line.starts_with("revision")) {
      size_t lookAhead = sizeof("revision") + 1;
      while (lookAhead < line.size() - 1) {
        if (line[lookAhead] == ' ' || line[lookAhead] == '=') {
          lookAhead++;
          continue;
        }
        break;
      }
      revision = line.substr(lookAhead);
      continue;
    }
    if (line.starts_with("patch_") || line.starts_with("diff_files")) {
      goto makeDefault;
    }
  }
  file.close();
  if (!isGit && !isFile) {
    goto makeDefault;
  }
  if (isFile && !url.empty()) {
    return normalizeURLToFilePath(url);
  }
  if (isGit && !url.empty()) {
    return hash(url + "//" + revision);
  }
makeDefault:
  auto ftime = std::filesystem::last_write_time(path);
  const auto systemTime =
      std::chrono::clock_cast<std::chrono::system_clock>(ftime);
  const auto time = std::chrono::system_clock::to_time_t(systemTime);
  return std::format("{}-{}", hash(path), time);
};

static std::string normalizeURLToFilePath(const std::string &url) {
  std::string normalizedPath = url;
  std::replace_if(
      normalizedPath.begin(), normalizedPath.end(),
      [](char chr) {
        return (isalnum(chr) == 0) && chr != '.' && chr != '-' && chr != '/' &&
               chr != ':';
      },
      '_');
  size_t pos = 0;
  while ((pos = normalizedPath.find("//", pos)) != std::string::npos) {
    normalizedPath.replace(pos, 2, "_");
    pos += 1;
  }

  pos = 0;

  while ((pos = normalizedPath.find('/', pos)) != std::string::npos) {
    normalizedPath.replace(pos, 1, "_");
    pos += 1;
  }
  pos = normalizedPath.find(':');
  if (pos != std::string::npos) {
    normalizedPath.replace(pos, 1, "_");
  }

  return normalizedPath;
}
