#include "ini.hpp"
#include <cstring>

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
  if (strcmp(node_type, "document") == 0)
    return std::make_shared<ast::ini::IniFile>(file, node);
  if (strcmp(node_type, "section") == 0)
    return std::make_shared<ast::ini::Section>(file, node);
  if (strcmp(node_type, "section_name") == 0)
    return std::make_shared<ast::ini::StringValue>(
        file, ts_node_named_child(node, 0));
  if (strcmp(node_type, "setting") == 0)
    return std::make_shared<ast::ini::KeyValuePair>(file, node);
  return std::make_shared<ast::ini::ErrorNode>(
      file, node, std::format("Unknown node_type '{}'", node_type));
}