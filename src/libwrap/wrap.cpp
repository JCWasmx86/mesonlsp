#include "wrap.hpp"
#include "ini.hpp"
#include "log.hpp"
#include "sourcefile.hpp"
#include "utils.hpp"
#include <cstddef>
#include <filesystem>
#include <format>
#include <fstream>
#include <memory>
#include <sstream>
#include <string>
#include <tree_sitter/api.h>
#include <utility>
#include <vector>

static Logger LOG("wrap::Wrap"); // NOLINT

extern "C" TSLanguage *tree_sitter_ini(); // NOLINT

Wrap::Wrap(ast::ini::Section *section) {
  if (auto val = section->findStringValue("directory")) {
    this->directory = val.value();
  } else {
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

void Wrap::applyPatch(std::filesystem::path path,
                      std::filesystem::path packageFilesPath) {
  if (this->patchDirectory.has_value()) {
    auto packagePath = packageFilesPath / this->patchDirectory.value();
    LOG.info(
        std::format("Merging {} into {}", packagePath.c_str(), path.c_str()));
    mergeDirectories(packagePath, std::move(path));
    return;
  }
  auto patchFilename = this->patchFilename;
  if (!patchFilename.has_value() || patchFilename->empty()) {
    return;
  }
  auto patchUrl = this->patchUrl;
  if (!patchUrl.has_value() || patchUrl->empty()) {
    return;
  }
  auto patchHash = this->patchHash;
  if (!patchHash.has_value() || patchHash->empty()) {
    return;
  }
  auto archiveFileName = std::filesystem::path{randomFile()};
  downloadFile(patchUrl.value(), archiveFileName);
  extractFile(archiveFileName, path.parent_path());
}

void Wrap::applyDiffFiles(std::filesystem::path path,
                          std::filesystem::path packageFilesPath) {
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
    }
  }
}

void Wrap::postSetup(std::filesystem::path path,
                     std::filesystem::path packageFilesPath) {
  this->applyPatch(path, packageFilesPath);
  this->applyDiffFiles(path, packageFilesPath);
}

std::shared_ptr<WrapFile> parseWrap(std::filesystem::path path) {
  std::ifstream file(path);
  auto fileSize = std::filesystem::file_size(path);
  std::string fileContent;
  fileContent.resize(fileSize, '\0');
  file.read(fileContent.data(), fileSize);
  TSParser *parser = ts_parser_new();
  ts_parser_set_language(parser, tree_sitter_ini());
  TSTree *tree = ts_parser_parse_string(parser, NULL, fileContent.data(),
                                        fileContent.length());
  TSNode rootNode = ts_tree_root_node(tree);
  auto sourceFile = std::make_shared<SourceFile>(path);
  auto root = ast::ini::makeNode(sourceFile, rootNode);
  ts_tree_delete(tree);
  ts_parser_delete(parser);
  auto iniFile = dynamic_cast<ast::ini::IniFile *>(root.get());
  if ((iniFile == nullptr) || iniFile->sections.empty()) {
    return std::make_shared<WrapFile>(nullptr, nullptr);
  }
  if (iniFile->sections.size() > 2) { // wrap-* section + maybe provides section
    return std::make_shared<WrapFile>(nullptr, root);
  }
  // Search for the right section
  auto section = dynamic_cast<ast::ini::Section *>(iniFile->sections[0].get());
  if (section == nullptr) {
    return std::make_shared<WrapFile>(nullptr, root);
  }
  auto sectionName = dynamic_cast<ast::ini::StringValue *>(section->name.get());
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
