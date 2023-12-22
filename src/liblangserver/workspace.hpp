#pragma once

#include "langserverutils.hpp"
#include "lsptypes.hpp"
#include "mesontree.hpp"
#include "task.hpp"
#include "typenamespace.hpp"

#include <filesystem>

class Workspace {
public:
  std::filesystem::path root;
  std::string name;
  std::map<std::string /*Identifier*/, Task *> tasks;
  std::mutex mtx;

  Workspace(const WorkspaceFolder &wspf) {
    this->root = extractPathFromUrl(wspf.uri);
    this->name = wspf.name;
  }

  std::map<std::filesystem::path, std::vector<LSPDiagnostic>>
  parse(const TypeNamespace &ns);

  bool owns(const std::filesystem::path &path);

  void
  patchFile(std::filesystem::path path, std::string contents,
            std::function<void(
                std::map<std::filesystem::path, std::vector<LSPDiagnostic>>)>
                func);
  std::vector<InlayHint> inlayHints(const std::filesystem::path &path);

private:
  std::shared_ptr<MesonTree> tree;
};
