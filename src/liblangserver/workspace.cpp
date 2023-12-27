#include "workspace.hpp"

#include "analysisoptions.hpp"
#include "documentsymbolvisitor.hpp"
#include "foldingrangevisitor.hpp"
#include "hover.hpp"
#include "inlayhintvisitor.hpp"
#include "langserverutils.hpp"
#include "lsptypes.hpp"
#include "mesontree.hpp"
#include "node.hpp"
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

std::optional<Hover> Workspace::hover(const std::filesystem::path &path,
                                      const LSPPosition &position) {
  std::lock_guard<std::mutex> lock(dataCollectionMtx);
  for (const auto &subTree : findTrees(this->tree)) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto metadata = subTree->metadata;
    auto feOpt = metadata.findFunctionExpressionAt(path, position.line,
                                                   position.character);
    if (feOpt.has_value()) {
      return makeHoverForFunctionExpression(feOpt.value());
    }
    auto meOpt = metadata.findMethodExpressionAt(path, position.line,
                                                 position.character);
    if (meOpt.has_value()) {
      return makeHoverForMethodExpression(meOpt.value());
    }
    auto idExprOpt =
        metadata.findIdExpressionAt(path, position.line, position.character);
    if (idExprOpt.has_value()) {
      return makeHoverForId(idExprOpt.value());
    }
    return {};
  }
  return std::nullopt;
}

std::vector<DocumentHighlight>
Workspace::highlight(const std::filesystem::path &path,
                     const LSPPosition &position) {
  std::lock_guard<std::mutex> lock(dataCollectionMtx);
  for (const auto &subTree : findTrees(this->tree)) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto metadata = subTree->metadata;
    if (!metadata.identifiers.contains(path)) {
      continue;
    }
    auto idExpr =
        metadata.findIdExpressionAt(path, position.line, position.character);
    if (!idExpr) {
      return {};
    }
    auto identifiers = metadata.identifiers[path];
    std::vector<DocumentHighlight> ret;
    for (const auto &toCheck : identifiers) {
      if (idExpr.value()->id != toCheck->id) {
        continue;
      }
      auto kind = DocumentHighlightKind::ReadKind;
      auto *ass = dynamic_cast<AssignmentStatement *>(toCheck->parent);
      if (ass && toCheck->equals(ass->lhs.get())) {
        kind = DocumentHighlightKind::WriteKind;
      }
      const auto *loc = toCheck->location;
      auto range = LSPRange(LSPPosition(loc->startLine, loc->startColumn),
                            LSPPosition(loc->endLine, loc->endColumn));
      ret.emplace_back(range, kind);
    }
    return ret;
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

std::optional<WorkspaceEdit>
Workspace::rename(const std::filesystem::path &path,
                  const RenameParams &params) {
  std::lock_guard<std::mutex> lock(dataCollectionMtx);
  for (const auto &subTree : findTrees(this->tree)) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto metadata = subTree->metadata;
    auto toRenameOpt = metadata.findIdExpressionAt(path, params.position.line,
                                                   params.position.character);
    if (!toRenameOpt.has_value()) {
      return std::nullopt;
    }
    auto *toRename = toRenameOpt.value();
    WorkspaceEdit ret;
    auto foundOurself = false;
    for (const auto &pair : metadata.identifiers) {
      auto url = pathToUrl(pair.first);
      ret.changes[url] = {};
      for (auto *identifier : pair.second) {
        if (identifier->id != toRename->id) {
          continue;
        }
        if (identifier->equals(toRename)) {
          if (foundOurself) {
            continue;
          }
          foundOurself = true;
        }
        const auto *loc = identifier->location;
        auto range = LSPRange(LSPPosition(loc->startLine, loc->startColumn),
                              LSPPosition(loc->endLine, loc->endColumn));
        ret.changes[url].emplace_back(range, params.newName);
      }
    }
    return ret;
  }
  return std::nullopt;
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

std::vector<SymbolInformation>
Workspace::documentSymbols(const std::filesystem::path &path) {
  std::lock_guard<std::mutex> lock(dataCollectionMtx);
  for (const auto &subTree : findTrees(this->tree)) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto ast = subTree->asts[path];
    auto visitor = DocumentSymbolVisitor();
    ast->visit(&visitor);
    return visitor.symbols;
  }
  return {};
}

void Workspace::dropCache(const std::filesystem::path &path) {
  for (const auto &subTree : findTrees(this->tree)) {
    if (!subTree->ownedFiles.contains(path) ||
        !subTree->overrides.contains(path)) {
      continue;
    }
    auto iter = subTree->overrides.find(path);
    subTree->overrides.erase(iter);
  }
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
