#include "wrap.hpp"

#include "ini.hpp"
#include "log.hpp"
#include "sourcefile.hpp"
#include "utils.hpp"

#include <filesystem>
#include <format>
#include <fstream>
#include <memory>
#include <sstream>
#include <string>
#include <tree_sitter/api.h>
#include <vector>

const static Logger LOG("wrap::Wrap"); // NOLINT

extern "C" TSLanguage *tree_sitter_ini(); // NOLINT

Wrap::Wrap(ast::ini::Section *section) {
  if (auto val = section->findStringValue("directory")) {
    this->directory = val.value();
    LOG.info(
        std::format("Directory according to the wrap file: {}", val.value()));
  } else {
    LOG.info(std::format("Guessed: {}->{}", section->file->file.c_str(),
                         section->file->file.stem().c_str()));
    this->directory = section->file->file.stem();
  }
  if (auto val = section->findStringValue("patch_url")) {
    this->patchUrl = val.value();
  }
  if (auto val = section->findStringValue("patch_fallback_url")) {
    this->patchFallbackUrl = val.value();
  }
  if (auto val = section->findStringValue("patch_filename")) {
    this->patchFilename = val.value();
  }
  if (auto val = section->findStringValue("patch_hash")) {
    this->patchHash = val;
  }
  if (auto val = section->findStringValue("patch_directory")) {
    this->patchDirectory = val;
  }
  if (auto val = section->findStringValue("diff_files")) {
    std::string segment;
    std::stringstream strm(val.value());
    while (std::getline(strm, segment, ',')) {
      this->diffFiles.push_back(segment);
    }
  }
  if (auto val = section->findStringValue("method")) {
    this->method = val;
  }
}

bool Wrap::applyPatch(const std::filesystem::path &path,
                      const std::filesystem::path &packageFilesPath) {
  if (this->patchDirectory.has_value()) {
    auto packagePath = packageFilesPath / this->patchDirectory.value();
    if (!std::filesystem::exists(packagePath)) {
      LOG.warn(
          std::format("Patchdirectory {} does not exist", packagePath.c_str()));
      return false;
    }
    LOG.info(
        std::format("Merging {} into {}", packagePath.c_str(), path.c_str()));
    mergeDirectories(packagePath, path);
    return true;
  }
  auto patchFilename = this->patchFilename;
  if (!patchFilename.has_value() || patchFilename->empty()) {
    return true;
  }
  auto patchUrl = this->patchUrl;
  if (!patchUrl.has_value() || patchUrl->empty()) {
    return false;
  }
  auto patchHash = this->patchHash;
  if (!patchHash.has_value() || patchHash->empty()) {
    return false;
  }
  auto archiveFileName = downloadWithFallback(
      patchUrl.value(), patchHash.value(), this->patchFallbackUrl);
  if (!archiveFileName.has_value()) {
    LOG.warn("Unable to continue with setting up this wrap...");
    return false;
  }
  return extractFile(archiveFileName.value(), path.parent_path());
}

bool Wrap::applyDiffFiles(const std::filesystem::path &path,
                          const std::filesystem::path &packageFilesPath) {
  for (const auto &diff : this->diffFiles) {
    LOG.info(std::format("Applying diff: {}", diff));
    auto absoluteDiffPath = std::filesystem::absolute(packageFilesPath / diff);
    auto result = launchProcess(
        "git",
        std::vector<std::string>{"-C", path, "--work-tree", ".", "apply", "-p1",
                                 absoluteDiffPath.generic_string()});
    if (!result) {
      LOG.info(std::format("Retrying with `patch`"));
      result = launchProcess("patch", std::vector<std::string>{
                                          "-d", path, "-f", "-p1", "-i", path});
      if (!result) {
        LOG.warn("Won't continue setting up this wrap...");
        return false;
      }
    }
  }
  return true;
}

bool Wrap::postSetup(const std::filesystem::path &path,
                     const std::filesystem::path &packageFilesPath) {
  if (!this->applyPatch(path, packageFilesPath)) {
    LOG.warn("Failed during applying patches");
    return false;
  }
  if (!this->applyDiffFiles(path, packageFilesPath)) {
    LOG.warn("Failed during applying diffs");
    return false;
  }
  this->successfullySetup = true;
  return true;
}

std::shared_ptr<WrapFile> parseWrap(const std::filesystem::path &path) {
  std::ifstream file(path);
  auto fileSize = std::filesystem::file_size(path);
  std::string fileContent;
  fileContent.resize(fileSize, '\0');
  file.read(fileContent.data(), fileSize);
  TSParser *parser = ts_parser_new();
  ts_parser_set_language(parser, tree_sitter_ini());
  TSTree *tree = ts_parser_parse_string(parser, nullptr, fileContent.data(),
                                        fileContent.length());
  TSNode const rootNode = ts_tree_root_node(tree);
  auto sourceFile = std::make_shared<SourceFile>(path);
  auto root = ast::ini::makeNode(sourceFile, rootNode);
  ts_tree_delete(tree);
  ts_parser_delete(parser);
  auto *iniFile = dynamic_cast<ast::ini::IniFile *>(root.get());
  if ((iniFile == nullptr) || iniFile->sections.empty()) {
    return std::make_shared<WrapFile>(nullptr, nullptr);
  }
  if (iniFile->sections.size() > 2) { // wrap-* section + maybe provides section
    return std::make_shared<WrapFile>(nullptr, root);
  }
  // Search for the right section
  auto *section = dynamic_cast<ast::ini::Section *>(iniFile->sections[0].get());
  if (section == nullptr) {
    return std::make_shared<WrapFile>(nullptr, root);
  }
  auto *sectionName =
      dynamic_cast<ast::ini::StringValue *>(section->name.get());
  if (sectionName == nullptr) {
    return std::make_shared<WrapFile>(nullptr, root);
  }
  auto wrapType = sectionName->value;
  if (wrapType == "wrap-git") {
    return std::make_shared<WrapFile>(std::make_shared<GitWrap>(section), root);
  }
  if (wrapType == "wrap-svn") {
    return std::make_shared<WrapFile>(std::make_shared<SvnWrap>(section), root);
  }
  if (wrapType == "wrap-hg") {
    return std::make_shared<WrapFile>(std::make_shared<HgWrap>(section), root);
  }
  if (wrapType == "wrap-file") {
    return std::make_shared<WrapFile>(std::make_shared<FileWrap>(section),
                                      root);
  }
  return std::make_shared<WrapFile>(nullptr, root);
}
