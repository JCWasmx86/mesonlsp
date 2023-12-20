#pragma once

#include "langserverutils.hpp"
#include "lsptypes.hpp"
#include "mesontree.hpp"
#include "typenamespace.hpp"

#include <filesystem>

class Workspace {
public:
  std::filesystem::path root;
  std::string name;

  Workspace(const WorkspaceFolder &wspf) {
    this->root = extractPathFromUrl(wspf.uri);
    this->name = wspf.name;
  }

  std::map<std::filesystem::path, std::vector<LSPDiagnostic>>
  parse(const TypeNamespace &ns);

private:
  std::shared_ptr<MesonTree> tree;
};
