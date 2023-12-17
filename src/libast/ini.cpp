#include "ini.hpp"

#include "location.hpp"
#include "sourcefile.hpp"
#include "utils.hpp"

#include <cstdint>
#include <cstring>
#include <format>
#include <memory>
#include <optional>
#include <string>
#include <tree_sitter/api.h>
#include <utility>

std::optional<std::string>
ast::ini::Section::findStringValue(const std::string &key) {
  for (auto &keyValuePair : this->key_value_pairs) {
    auto *kvp = dynamic_cast<ast::ini::KeyValuePair *>(keyValuePair.get());
    if (kvp == nullptr) {
      continue;
    }
    auto *keyN = dynamic_cast<ast::ini::StringValue *>(kvp->key.get());
    if ((keyN == nullptr) || keyN->value != key) {
      continue;
    }
    auto *value = dynamic_cast<ast::ini::StringValue *>(kvp->value.get());
    if (value == nullptr) {
      continue;
    }
    return std::optional<std::string>(value->value);
  }
  return std::nullopt;
}

ast::ini::Node::Node(std::shared_ptr<SourceFile> file, TSNode node)
    : file(std::move(file)), location(new Location(node)) {}

ast::ini::IniFile::IniFile(std::shared_ptr<SourceFile> file, TSNode node)
    : ast::ini::Node(file, node) {
  for (uint32_t i = 0; i < ts_node_named_child_count(node); i++) {
    this->sections.push_back(
        ast::ini::makeNode(file, ts_node_named_child(node, i)));
  }
}

ast::ini::StringValue::StringValue(std::shared_ptr<SourceFile> file,
                                   TSNode node)
    : ast::ini::Node(file, node) {
  this->value = file->extractNodeValue(node);
  trim(this->value);
}

ast::ini::KeyValuePair::KeyValuePair(std::shared_ptr<SourceFile> file,
                                     TSNode node)
    : ast::ini::Node(file, node) {
  this->key = ast::ini::makeNode(file, ts_node_named_child(node, 0));
  this->value = ast::ini::makeNode(file, ts_node_named_child(node, 1));
}

ast::ini::Section::Section(std::shared_ptr<SourceFile> file, TSNode node)
    : ast::ini::Node(file, node) {
  this->name = ast::ini::makeNode(file, ts_node_named_child(node, 0));
  for (uint32_t i = 1; i < ts_node_named_child_count(node); i++) {
    this->key_value_pairs.push_back(
        ast::ini::makeNode(file, ts_node_named_child(node, i)));
  }
}

std::shared_ptr<ast::ini::Node>
ast::ini::makeNode(std::shared_ptr<SourceFile> file, TSNode node) {
  const auto *const nodeType = ts_node_type(node);
  if (strcmp(nodeType, "document") == 0) {
    return std::make_shared<ast::ini::IniFile>(file, node);
  }
  if (strcmp(nodeType, "section") == 0) {
    return std::make_shared<ast::ini::Section>(file, node);
  }
  if (strcmp(nodeType, "section_name") == 0) {
    return std::make_shared<ast::ini::StringValue>(
        file, ts_node_named_child(node, 0));
  }
  if (strcmp(nodeType, "setting_name") == 0 ||
      strcmp(nodeType, "setting_value") == 0) {
    return std::make_shared<ast::ini::StringValue>(file, node);
  }
  if (strcmp(nodeType, "setting") == 0) {
    return std::make_shared<ast::ini::KeyValuePair>(file, node);
  }
  return std::make_shared<ast::ini::ErrorNode>(
      file, node, std::format("Unknown node_type '{}'", nodeType));
}