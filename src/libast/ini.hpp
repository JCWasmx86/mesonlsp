#pragma once
#include "location.hpp"

#include "sourcefile.hpp"
#include <memory>
#include <tree_sitter/api.h>
#include <vector>

namespace ast::ini {
class Node {
public:
  const std::shared_ptr<SourceFile> file;
  const Location *location;

  virtual ~Node() {
    delete this->location;
    this->location = nullptr;
  }

protected:
  Node(std::shared_ptr<SourceFile> file, TSNode node);
};

class StringValue : public ast::ini::Node {
public:
  std::string value;
  StringValue(std::shared_ptr<SourceFile> file, TSNode node);
};

class ErrorNode : public Node {
public:
  std::string message;
  ErrorNode(std::shared_ptr<SourceFile> file, TSNode node, std::string message)
      : Node(file, node), message(message) {}
};

class KeyValuePair : public ast::ini::Node {
public:
  std::shared_ptr<ast::ini::Node> key;
  std::shared_ptr<ast::ini::Node> value;
  KeyValuePair(std::shared_ptr<SourceFile> file, TSNode node);
};

class Section : public ast::ini::Node {
public:
  std::shared_ptr<ast::ini::Node> name;
  std::vector<std::shared_ptr<ast::ini::Node>> key_value_pairs;
  Section(std::shared_ptr<SourceFile> file, TSNode node);
};

class IniFile : public ast::ini::Node {
public:
  std::vector<std::shared_ptr<ast::ini::Node>> sections;

  IniFile(std::shared_ptr<SourceFile> file, TSNode node);
};

std::shared_ptr<Node> make_node(std::shared_ptr<SourceFile> file, TSNode node);

} // namespace ast::ini
