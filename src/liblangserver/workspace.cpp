#include "workspace.hpp"

#include "analysisoptions.hpp"
#include "mesontree.hpp"
#include "typenamespace.hpp"

#include <memory>

std::vector<std::shared_ptr<MesonTree>>
findTrees(std::shared_ptr<MesonTree> root) {
  std::vector<std::shared_ptr<MesonTree>> ret;
  ret.emplace_back(root);
  for (const auto &subproj : root->state->subprojects) {
    if (subproj->tree) {
      auto recursiveTrees = findTrees(subproj->tree);
      ret.insert(ret.end(), recursiveTrees.begin(), recursiveTrees.end());
    }
  }
  return ret;
}

std::map<std::filesystem::path, std::vector<LSPDiagnostic>>
Workspace::parse(const TypeNamespace &ns) {
  auto tree = std::make_shared<MesonTree>(this->root, ns);
  tree->fullParse(
      AnalysisOptions(false, false, false, false, false, false, false));
  tree->identifier = this->name;
  this->tree = tree;
  std::map<std::filesystem::path, std::vector<LSPDiagnostic>> ret;
  for (auto subTree : findTrees(this->tree)) {
    auto metadata = subTree->metadata;
    for (auto pair : metadata.diagnostics) {
      if (!ret.contains(pair.first)) {
        ret[pair.first] = {};
      }
      for (auto diag : pair.second) {
        ret[pair.first].push_back(makeLSPDiagnostic(diag));
      }
    }
  }
  return ret;
}
