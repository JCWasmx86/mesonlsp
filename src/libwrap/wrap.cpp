#include "wrap.hpp"
#include "ini.hpp"
#include "sourcefile.hpp"
#include <cstddef>
#include <fstream>
#include <memory>
#include <sstream>
#include <string>
#include <tree_sitter/api.h>

extern "C" TSLanguage *tree_sitter_ini();

Wrap::Wrap(ast::ini::Section *section) {
  if (auto val = section->find_string_value("directory")) {
    this->directory = val.value();
  }
  if (auto val = section->find_string_value("patch_url")) {
    this->patchUrl = val.value();
  }
  if (auto val = section->find_string_value("patch_fallback_url")) {
    this->patchFallbackUrl = val.value();
  }
  if (auto val = section->find_string_value("patch_filename")) {
    this->patchFilename = val.value();
  }
  if (auto val = section->find_string_value("patch_hash")) {
    this->patchHash = val;
  }
  if (auto val = section->find_string_value("patch_directory")) {
    this->patchDirectory = val;
  }
  if (auto val = section->find_string_value("diff_files")) {
    std::string segment;
    std::stringstream strm(val.value());
    while (std::getline(strm, segment, ',')) {
      this->diff_files.push_back(segment);
    }
  }
  if (auto val = section->find_string_value("method")) {
    this->method = val;
  }
}

std::shared_ptr<WrapFile> parse_wrap(std::filesystem::path path) {
  std::ifstream file(path);
  auto file_size = std::filesystem::file_size(path);
  std::string file_content;
  file_content.resize(file_size, '\0');
  file.read(file_content.data(), file_size);
  TSParser *parser = ts_parser_new();
  ts_parser_set_language(parser, tree_sitter_ini());
  TSTree *tree = ts_parser_parse_string(parser, NULL, file_content.data(),
                                        file_content.length());
  TSNode root_node = ts_tree_root_node(tree);
  auto source_file = std::make_shared<SourceFile>(path);
  auto root = ast::ini::make_node(source_file, root_node);
  ts_tree_delete(tree);
  ts_parser_delete(parser);
  auto ini_file = dynamic_cast<ast::ini::IniFile *>(root.get());
  if (!ini_file || !ini_file->sections.size()) {
    return std::make_shared<WrapFile>(nullptr, nullptr);
  }
  if (ini_file->sections.size() >
      2) { // wrap-* section + maybe provides section
    return std::make_shared<WrapFile>(nullptr, root);
  }
  // Search for the right section
  auto section = dynamic_cast<ast::ini::Section *>(ini_file->sections[0].get());
  if (!section) {
    return std::make_shared<WrapFile>(nullptr, root);
  }
  auto section_name =
      dynamic_cast<ast::ini::StringValue *>(section->name.get());
  if (!section_name) {
    return std::make_shared<WrapFile>(nullptr, root);
  }
  auto wrap_type = section_name->value;
  if (wrap_type == "wrap-git") {
    return std::make_shared<WrapFile>(std::make_shared<GitWrap>(section), root);
  }
  if (wrap_type == "wrap-svn") {
    return std::make_shared<WrapFile>(std::make_shared<SvnWrap>(section), root);
  }
  if (wrap_type == "wrap-hg") {
    return std::make_shared<WrapFile>(std::make_shared<HgWrap>(section), root);
  }
  if (wrap_type == "wrap-file") {
    return std::make_shared<WrapFile>(std::make_shared<FileWrap>(section),
                                      root);
  }
  return std::make_shared<WrapFile>(nullptr, root);
}
