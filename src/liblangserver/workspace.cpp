#include "workspace.hpp"

#include "analysisoptions.hpp"
#include "inlayhintvisitor.hpp"
#include "mesontree.hpp"
#include "typenamespace.hpp"

#include <future>
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

bool Workspace::owns(const std::filesystem::path &path) {
  for (const auto &subTree : findTrees(this->tree)) {
    if (subTree->ownedFiles.contains(path)) {
      return true;
    }
  }
  return false;
}

std::vector<InlayHint>
Workspace::inlayHints(const std::filesystem::path &path) {
  for (const auto &subTree : findTrees(this->tree)) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto ast = subTree->asts[path];
    auto visitor = InlayHintVisitor();
    ast->visit(&visitor);
    return visitor.hints;
  }
  return {};
}

void Workspace::patchFile(
    std::filesystem::path path, std::string contents,
    std::function<
        void(std::map<std::filesystem::path, std::vector<LSPDiagnostic>>)>
        func) {
  std::lock_guard<std::mutex> lock(mtx);
  for (const auto &subTree : findTrees(this->tree)) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    std::set<std::filesystem::path> oldDiags;
    for (const auto &pair : subTree->metadata.diagnostics) {
      oldDiags.insert(pair.first);
    }
    subTree->clear();
    auto identifier = subTree->identifier;
    if (this->tasks.contains(identifier)) {
      auto *tsk = this->tasks[identifier];
      while (tsk->state != TaskState::Ended) {
      }
      delete tsk;
    }
    subTree->overrides[path] = contents;
    auto *newTask = new Task([&subTree, func, oldDiags]() {
      subTree->partialParse(
          AnalysisOptions(false, false, false, false, false, false, false));
      std::map<std::filesystem::path, std::vector<LSPDiagnostic>> ret;
      auto metadata = subTree->metadata;
      for (const auto &pair : metadata.diagnostics) {
        if (!ret.contains(pair.first)) {
          ret[pair.first] = {};
        }
        for (const auto &diag : pair.second) {
          ret[pair.first].push_back(makeLSPDiagnostic(diag));
        }
      }
      for (const auto &oldDiag : oldDiags) {
        if (!ret.contains(oldDiag)) {
          ret[oldDiag] = {};
        }
      }
      func(ret);
    });
    (void)std::async(std::launch::async, &Task::run, newTask);
    this->tasks[identifier] = newTask;
  }
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
