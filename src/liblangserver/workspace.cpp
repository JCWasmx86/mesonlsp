#include "workspace.hpp"

#include "analysisoptions.hpp"
#include "foldingrangevisitor.hpp"
#include "inlayhintvisitor.hpp"
#include "mesontree.hpp"
#include "semantictokensvisitor.hpp"
#include "typenamespace.hpp"

#include <exception>
#include <filesystem>
#include <future>
#include <memory>
#include <optional>

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
  std::lock_guard<std::mutex> lock(dataCollectionMtx);
  for (const auto &subTree : findTrees(this->tree)) {
    if (subTree->ownedFiles.contains(path)) {
      return true;
    }
  }
  return false;
}

std::vector<InlayHint>
Workspace::inlayHints(const std::filesystem::path &path) {
  std::lock_guard<std::mutex> lock(dataCollectionMtx);
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

std::vector<uint64_t>
Workspace::semanticTokens(const std::filesystem::path &path) {
  std::lock_guard<std::mutex> lock(dataCollectionMtx);
  for (const auto &subTree : findTrees(this->tree)) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto ast = subTree->asts[path];
    auto visitor = SemanticTokensVisitor();
    ast->visit(&visitor);
    return visitor.finish();
  }
  return {};
}

std::vector<FoldingRange>
Workspace::foldingRanges(const std::filesystem::path &path) {
  std::lock_guard<std::mutex> lock(dataCollectionMtx);
  for (const auto &subTree : findTrees(this->tree)) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto ast = subTree->asts[path];
    auto visitor = FoldingRangeVisitor();
    ast->visit(&visitor);
    return visitor.ranges;
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
    auto identifier = subTree->identifier;
    {
      std::lock_guard<std::mutex> lockEverythingElse(this->dataCollectionMtx);
      for (const auto &pair : subTree->metadata.diagnostics) {
        oldDiags.insert(pair.first);
      }
      subTree->clear();
      if (this->tasks.contains(identifier)) {
        auto *tsk = this->tasks[identifier];
        this->logger.info(
            std::format("Waiting for {} to terminate", tsk->getUUID()));
        while (tsk->state != TaskState::Ended) {
        }
        this->logger.info(
            std::format("{} finally terminated...", tsk->getUUID()));
        delete tsk;
      }
      subTree->overrides[path] = contents;
    }
    auto *newTask = new Task([&subTree, func, oldDiags, this]() {
      std::lock_guard<std::mutex> lockEverythingElse(this->dataCollectionMtx);
      std::exception_ptr exception = nullptr;
      try {
        subTree->partialParse(
            AnalysisOptions(false, false, false, false, false, false, false));

      } catch (...) {
        exception = std::current_exception();
      }

      std::map<std::filesystem::path, std::vector<LSPDiagnostic>> ret;

      if (exception) {
        for (const auto &oldDiag : oldDiags) {
          ret[oldDiag] = {};
        }
        func(ret);
        std::rethrow_exception(exception);
        return;
      }
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

std::optional<std::filesystem::path>
Workspace::muonConfigFile(const std::filesystem::path &path) {
  for (const auto &tree : findTrees(this->tree)) {
    auto treePath = tree->root;
    if (std::filesystem::relative(path, treePath)
            .generic_string()
            .contains("..")) {
      continue;
    }
    auto iniFile = treePath / "muon_fmt.ini";
    if (std::filesystem::exists(iniFile)) {
      return iniFile;
    }
    break;
  }
  return std::nullopt;
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
