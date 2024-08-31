#include "subprojectstate.hpp"

#include "analysisoptions.hpp"
#include "log.hpp"
#include "mesontree.hpp"
#include "node.hpp"
#include "polyfill.hpp"
#include "subproject.hpp"
#include "typenamespace.hpp"
#include "utils.hpp"

#include <algorithm>
#include <cctype>
#include <chrono>
#include <cstddef>
#include <filesystem>
#include <fstream>
#include <memory>
#include <optional>
#include <string>

static const Logger LOG("analyze::subprojectstate"); // NOLINT

static std::string normalizeURLToFilePath(const std::string &url);

static std::string lookAhead(const std::string &line, size_t initialOffset);

static std::string getSubprojectBaseDir(MesonTree *&tree) {
  std::string subprojectsBaseDir = "subprojects";
  const auto &rootFile = tree->root / "meson.build";
  if (!tree->asts.contains(rootFile)) {
    return subprojectsBaseDir;
  }
  const auto &nodes = tree->asts.at(rootFile);
  for (const auto &node : nodes) {
    const auto *bd = dynamic_cast<BuildDefinition *>(node.get());
    if (!bd) {
      break;
    }
    if (bd->stmts.empty()) {
      break;
    }
    if (bd->stmts[0]->type != NodeType::FUNCTION_EXPRESSION) {
      break;
    }
    const auto *fe = dynamic_cast<FunctionExpression *>(bd->stmts[0].get());
    if (fe->functionName() != "project") {
      continue;
    }
    const auto alNode = fe->args;
    if (!alNode) {
      break;
    }
    const auto *al = dynamic_cast<ArgumentList *>(alNode.get());
    if (!al) {
      break;
    }
    const auto subprojectsBaseDirKwarg = al->getKwarg("subproject_dir");
    if (!subprojectsBaseDirKwarg) {
      break;
    }
    const auto *subprojectsDirSL =
        dynamic_cast<StringLiteral *>(subprojectsBaseDirKwarg->get());
    if (!subprojectsDirSL) {
      break;
    }
    subprojectsBaseDir = subprojectsDirSL->id;
  }
  return subprojectsBaseDir;
}

void SubprojectState::findSubprojects(bool downloadSubprojects,
                                      MesonTree *tree) {
  const std::string subprojectsBaseDir = getSubprojectBaseDir(tree);
  const auto &subprojectsDir =
      std::filesystem::absolute(this->root) / subprojectsBaseDir;
  if (!std::filesystem::exists(subprojectsDir) ||
      !std::filesystem::is_directory(subprojectsDir)) {
    return;
  }
  const auto &extractionDir = cacheDir() / "wrapsWorkspace";
  std::filesystem::create_directories(extractionDir);
  const auto &packageFiles = subprojectsDir / "packagefiles";
  for (const auto &entry :
       std::filesystem::directory_iterator(subprojectsDir)) {
    const auto &child = std::filesystem::absolute(entry.path());
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
    const auto &identifier = identifierOpt.value();
    LOG.info(std::format("{}: Identifier is: {}",
                         child.filename().generic_string(), identifier));
    const auto &wrapBaseDir = extractionDir / child.filename() / identifier;
    LOG.info(
        std::format("Extracting wrap to {}", wrapBaseDir.generic_string()));
    const auto &checkFile = wrapBaseDir / ".fullysetup";
    const auto &subprojectName = child.stem().string();
    if (std::filesystem::exists(checkFile)) {
      LOG.info("Wrap is already setup!");
      this->subprojects.emplace_back(std::make_shared<CachedSubproject>(
          subprojectName, wrapBaseDir / guessTargetDirectoryFromWrap(child)));
      continue;
    }
    if (downloadSubprojects) {
      if (std::filesystem::exists(wrapBaseDir)) {
        LOG.warn(
            std::format("{} exists, but is not fully setup => Reattempting",
                        wrapBaseDir.generic_string()));
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
    const auto &child = std::filesystem::absolute(entry.path());
    if (!std::filesystem::is_directory(child)) {
      continue;
    }
    const auto &filename = child.filename();
    if (filename == "packagefiles" || filename == "packagecache" ||
        std::filesystem::exists(child / ".meson-subproject-wrap-hash.txt")) {
      continue;
    }
    for (const auto &subproject : this->subprojects) {
      if (subproject->name == filename) {
        LOG.info(std::format("Found already registered subproject: {}",
                             subproject->name));
        continue;
      }
    }
    LOG.info(std::format("Found folder based subproject {}",
                         filename.generic_string()));
    this->subprojects.emplace_back(
        std::make_shared<FolderSubproject>(filename.generic_string(), child));
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

void SubprojectState::parseSubprojects(const AnalysisOptions &options,
                                       int depth,
                                       const std::string &parentIdentifier,
                                       const TypeNamespace &ns,
                                       bool downloadSubprojects,
                                       bool useCustomParser, MesonTree *tree) {
  for (const auto &subproject : this->subprojects) {
    subproject->parse(options, depth, parentIdentifier, ns, downloadSubprojects,
                      useCustomParser, tree);
  }
}

static std::string lookAhead(const std::string &line, size_t initialOffset) {
  size_t lookAhead = initialOffset;
  while (lookAhead < line.size() - 1) {
    if (line[lookAhead] == ' ' || line[lookAhead] == '=') {
      lookAhead++;
      continue;
    }
    break;
  }
  return line.substr(lookAhead);
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
      url = lookAhead(line, 4);
      continue;
    }
    if (line.starts_with("source_url")) {
      url = lookAhead(line, sizeof("source_url") + 1);
      continue;
    }
    if (line.starts_with("revision")) {
      revision = lookAhead(line, sizeof("revision") + 1);
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
#ifdef __linux__
  auto ftime = std::filesystem::last_write_time(path);
  const auto systemTime =
      std::chrono::clock_cast<std::chrono::system_clock>(ftime);
  const auto time = std::chrono::system_clock::to_time_t(systemTime);
  return std::format("{}-{}", hash(path), time);

#else
  auto ftime = std::filesystem::last_write_time(path);
  auto duration =
      std::chrono::duration_cast<std::chrono::system_clock::duration>(
          ftime.time_since_epoch());
  std::chrono::system_clock::time_point epoch;
  auto time = std::chrono::system_clock::to_time_t(epoch + duration);
  return std::format("{}-{}", hash(path), time);
#endif
};

static std::string normalizeURLToFilePath(const std::string &url) {
  std::string normalizedPath = url;
  std::ranges::replace_if(
      normalizedPath,
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
