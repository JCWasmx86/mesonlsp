#include "node.hpp"
#include "location.hpp"
#include <cstring>
#include <format>
#include <memory>

Node::Node(std::shared_ptr<MesonSourceFile> file, TSNode node)
  : file(file)
  , location(new Location(node))
{
}

ArgumentList::ArgumentList(std::shared_ptr<MesonSourceFile> file, TSNode node)
  : Node(file, node)
{
  for (uint32_t i = 0; i < ts_node_named_child_count(node); i++) {
    this->args.push_back(make_node(file, ts_node_named_child(node, i)));
  }
}

ArrayLiteral::ArrayLiteral(std::shared_ptr<MesonSourceFile> file, TSNode node)
  : Node(file, node)
{
  for (uint32_t i = 0; i < ts_node_named_child_count(node); i++) {
    this->args.push_back(make_node(file, ts_node_named_child(node, i)));
  }
}

std::shared_ptr<Node>
make_node(std::shared_ptr<MesonSourceFile> file, TSNode node)
{
  auto node_type = ts_node_type(node);
  if (strcmp(node_type, "argument_list") == 0)
    return std::make_shared<ArgumentList>(file, node);
  else if (strcmp(node_type, "array_literal") == 0)
    return std::make_shared<ArrayLiteral>(file, node);
  return std::make_shared<ErrorNode>(
    file, node, std::format("Unknown node_type '{}'", node_type));
}