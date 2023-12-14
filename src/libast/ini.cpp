#include "ini.hpp"
#include "utils.hpp"
#include <cstring>
#include <optional>
#include <string>

std::optional<std::string>
ast::ini::Section::find_string_value(std::string key) {
  for (auto &key_value_pair : this->key_value_pairs) {
    auto kvp = dynamic_cast<ast::ini::KeyValuePair *>(key_value_pair.get());
    if (kvp == nullptr) {
      continue;
    }
    auto keyN = dynamic_cast<ast::ini::StringValue *>(kvp->key.get());
    if ((keyN == nullptr) || keyN->value != key) {
      continue;
    }
    auto value = dynamic_cast<ast::ini::StringValue *>(kvp->value.get());
    if (value == nullptr) {
      continue;
    }
    return std::optional<std::string>(value->value);
  }
  return std::nullopt;
}
ast::ini::Node::Node(std::shared_ptr<SourceFile> file, TSNode node)
    : file(file), location(new Location(node)) {}

ast::ini::IniFile::IniFile(std::shared_ptr<SourceFile> file, TSNode node)
    : ast::ini::Node(file, node) {
  for (uint32_t i = 0; i < ts_node_named_child_count(node); i++) {
    this->sections.push_back(
        ast::ini::make_node(file, ts_node_named_child(node, i)));
  }
}

ast::ini::StringValue::StringValue(std::shared_ptr<SourceFile> file,
                                   TSNode node)
    : ast::ini::Node(file, node) {
  this->value = file->extract_node_value(node);
  trim(this->value);
}

ast::ini::KeyValuePair::KeyValuePair(std::shared_ptr<SourceFile> file,
                                     TSNode node)
    : ast::ini::Node(file, node) {
  this->key = ast::ini::make_node(file, ts_node_named_child(node, 0));
  this->value = ast::ini::make_node(file, ts_node_named_child(node, 1));
}

ast::ini::Section::Section(std::shared_ptr<SourceFile> file, TSNode node)
    : ast::ini::Node(file, node) {
  this->name = ast::ini::make_node(file, ts_node_named_child(node, 0));
  for (uint32_t i = 1; i < ts_node_named_child_count(node); i++) {
    this->key_value_pairs.push_back(
        ast::ini::make_node(file, ts_node_named_child(node, i)));
  }
}

std::shared_ptr<ast::ini::Node>
ast::ini::make_node(std::shared_ptr<SourceFile> file, TSNode node) {
  auto node_type = ts_node_type(node);
  if (strcmp(node_type, "document") == 0) {
    return std::make_shared<ast::ini::IniFile>(file, node);
  }
  if (strcmp(node_type, "section") == 0) {
    return std::make_shared<ast::ini::Section>(file, node);
  }
  if (strcmp(node_type, "section_name") == 0) {
    return std::make_shared<ast::ini::StringValue>(
        file, ts_node_named_child(node, 0));
  }
  if (strcmp(node_type, "setting_name") == 0 ||
      strcmp(node_type, "setting_value") == 0) {
    return std::make_shared<ast::ini::StringValue>(file, node);
  }
  if (strcmp(node_type, "setting") == 0) {
    return std::make_shared<ast::ini::KeyValuePair>(file, node);
  }
  return std::make_shared<ast::ini::ErrorNode>(
      file, node, std::format("Unknown node_type '{}'", node_type));
}
