#pragma once
#include "location.hpp"
#include "sourcefile.hpp"

#include <memory>
#include <optional>
#include <string>
#include <tree_sitter/api.h>
#include <utility>
#include <vector>

namespace ast::ini {
class Node {
public:
  const std::shared_ptr<SourceFile> file;
  const Location location;

  virtual ~Node() = default;

protected:
  Node(std::shared_ptr<SourceFile> file, const TSNode &node);
};

class StringValue : public ast::ini::Node {
public:
  std::string value;
  StringValue(const std::shared_ptr<SourceFile> &file, const TSNode &node);
};

class ErrorNode : public Node {
public:
  std::string message;

  ErrorNode(std::shared_ptr<SourceFile> file, const TSNode &node,
            std::string message)
      : Node(std::move(file), node), message(std::move(message)) {}
};

class KeyValuePair : public ast::ini::Node {
public:
  std::shared_ptr<ast::ini::Node> key;
  std::shared_ptr<ast::ini::Node> value;
  KeyValuePair(const std::shared_ptr<SourceFile> &file, const TSNode &node);
};

class Section : public ast::ini::Node {
public:
  std::shared_ptr<ast::ini::Node> name;
  std::vector<std::shared_ptr<ast::ini::Node>> keyValuePairs;
  Section(const std::shared_ptr<SourceFile> &file, const TSNode &node);

  std::optional<std::string> findStringValue(const std::string &key);
};

class IniFile : public ast::ini::Node {
public:
  std::vector<std::shared_ptr<ast::ini::Node>> sections;

  IniFile(const std::shared_ptr<SourceFile> &file, const TSNode &node);
};

std::shared_ptr<Node> makeNode(const std::shared_ptr<SourceFile> &file,
                               const TSNode &node);

} // namespace ast::ini
