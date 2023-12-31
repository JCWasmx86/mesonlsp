#include "workspace.hpp"

#include "analysisoptions.hpp"
#include "codeactionvisitor.hpp"
#include "completion.hpp"
#include "documentsymbolvisitor.hpp"
#include "foldingrangevisitor.hpp"
#include "hover.hpp"
#include "inlayhintvisitor.hpp"
#include "langserverutils.hpp"
#include "lsptypes.hpp"
#include "mesonmetadata.hpp"
#include "mesontree.hpp"
#include "node.hpp"
#include "semantictokensvisitor.hpp"
#include "typenamespace.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <exception>
#include <filesystem>
#include <format>
#include <functional>
#include <future>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <set>
#include <string>
#include <vector>

std::vector<std::shared_ptr<MesonTree>>
findTrees(const std::shared_ptr<MesonTree> &root) {
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
  std::lock_guard<std::mutex> const lock(dataCollectionMtx);
  for (const auto &subTree : findTrees(this->tree)) {
    if (subTree->ownedFiles.contains(path)) {
      return true;
    }
  }
  return false;
}

std::vector<InlayHint>
Workspace::inlayHints(const std::filesystem::path &path) {
  std::lock_guard<std::mutex> const lock(dataCollectionMtx);
  for (const auto &subTree : findTrees(this->tree)) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto ast = subTree->asts[path];
    if (ast.empty()) {
      continue;
    }
    auto visitor = InlayHintVisitor();
    ast.back()->visit(&visitor);
    return visitor.hints;
  }
  return {};
}

std::optional<Hover> Workspace::hover(const std::filesystem::path &path,
                                      const LSPPosition &position) {
  std::lock_guard<std::mutex> const lock(dataCollectionMtx);
  for (const auto &subTree : findTrees(this->tree)) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto metadata = subTree->metadata;
    auto feOpt = metadata.findFunctionExpressionAt(path, position.line,
                                                   position.character);
    if (feOpt.has_value()) {
      return makeHoverForFunctionExpression(feOpt.value(), subTree->options);
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

std::vector<CodeAction> Workspace::codeAction(const std::filesystem::path &path,
                                              const LSPRange &range) {
  std::lock_guard<std::mutex> const lock(dataCollectionMtx);
  for (const auto &subTree : findTrees(this->tree)) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto ast = subTree->asts[path];
    if (ast.empty()) {
      continue;
    }
    auto visitor = CodeActionVisitor(range, pathToUrl(path), subTree.get());
    ast.back()->visit(&visitor);
    return visitor.actions;
  }
  return {};
}

std::vector<DocumentHighlight>
Workspace::highlight(const std::filesystem::path &path,
                     const LSPPosition &position) {
  std::lock_guard<std::mutex> const lock(dataCollectionMtx);
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
  std::lock_guard<std::mutex> const lock(dataCollectionMtx);
  for (const auto &subTree : findTrees(this->tree)) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto ast = subTree->asts[path];
    if (ast.empty()) {
      continue;
    }
    auto visitor = SemanticTokensVisitor();
    ast.back()->visit(&visitor);
    return visitor.finish();
  }
  return {};
}

std::vector<LSPLocation> Workspace::jumpTo(const std::filesystem::path &path,
                                           const LSPPosition &position) {
  std::lock_guard<std::mutex> const lock(dataCollectionMtx);
  // TODO: Jump to subdir/option
  for (const auto &subTree : findTrees(this->tree)) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    const auto &metadata = &subTree->metadata;
    auto foundMyself = false;
    std::string toFind;
    for (size_t i = metadata->encounteredIds.size() - 1; i > 0; i--) {
      if (i == (size_t)-1) {
        break;
      }
      const auto &idExpr = metadata->encounteredIds[i];
      if (MesonMetadata::contains(idExpr, position.line, position.character)) {
        foundMyself = true;
        toFind = idExpr->id;
      }
      if (!foundMyself || idExpr->id != toFind) {
        continue;
      }
      const auto *ass = dynamic_cast<AssignmentStatement *>(idExpr->parent);
      if (ass && ass->op == AssignmentOperator::Equals) {
        auto *lhsIdExpr = dynamic_cast<IdExpression *>(ass->lhs.get());
        if (lhsIdExpr && lhsIdExpr->id == toFind) {
          const auto *loc = idExpr->location;
          auto range = LSPRange(LSPPosition(loc->startLine, loc->startColumn),
                                LSPPosition(loc->endLine, loc->endColumn));
          return {LSPLocation(pathToUrl(idExpr->file->file), range)};
        }
      }
      if (dynamic_cast<IterationStatement *>(idExpr->parent)) {
        const auto *loc = idExpr->location;
        auto range = LSPRange(LSPPosition(loc->startLine, loc->startColumn),
                              LSPPosition(loc->endLine, loc->endColumn));
        return {LSPLocation(pathToUrl(idExpr->file->file), range)};
      }
    }
    if (!metadata->functionCalls.contains(path)) {
      return {};
    }
    for (const auto &funcCall : metadata->functionCalls.at(path)) {
      if (!MesonMetadata::contains(funcCall, position.line,
                                   position.character)) {
        continue;
      }
      if (funcCall->functionName() != "subdir") {
        return {};
      }
      auto key = std::format("{}-{}", funcCall->file->file.generic_string(),
                             funcCall->location->format());
      if (!metadata->subdirCalls.contains(key)) {
        return {};
      }
      const auto &set = metadata->subdirCalls.at(key);
      std::vector<std::string> sorted{set.begin(), set.end()};
      std::sort(sorted.begin(), sorted.end());
      std::vector<LSPLocation> ret;
      for (const auto &subdir : sorted) {
        auto subdirMesonPath = path.parent_path() / subdir / "meson.build";
        auto range = LSPRange(LSPPosition(0, 0), LSPPosition(0, 0));
        ret.emplace_back(pathToUrl(subdirMesonPath), range);
      }
      return ret;
    }
    break;
  }
  return {};
}

std::optional<WorkspaceEdit>
Workspace::rename(const std::filesystem::path &path,
                  const RenameParams &params) {
  std::lock_guard<std::mutex> const lock(dataCollectionMtx);
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
        // TODO: Rename parent-project `get_variable`
        ret.changes[url].emplace_back(range, params.newName);
      }
    }
    return ret;
  }
  return std::nullopt;
}

std::vector<FoldingRange>
Workspace::foldingRanges(const std::filesystem::path &path) {
  std::lock_guard<std::mutex> const lock(dataCollectionMtx);
  for (const auto &subTree : findTrees(this->tree)) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto ast = subTree->asts[path];
    if (ast.empty()) {
      continue;
    }
    auto visitor = FoldingRangeVisitor();
    ast.back()->visit(&visitor);
    return visitor.ranges;
  }
  return {};
}

std::vector<SymbolInformation>
Workspace::documentSymbols(const std::filesystem::path &path) {
  std::lock_guard<std::mutex> const lock(dataCollectionMtx);
  for (const auto &subTree : findTrees(this->tree)) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto ast = subTree->asts[path];
    if (ast.empty()) {
      continue;
    }
    auto visitor = DocumentSymbolVisitor();
    ast.back()->visit(&visitor);
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
    const std::filesystem::path &path, const std::string &contents,
    const std::function<void(
        std::map<std::filesystem::path, std::vector<LSPDiagnostic>>)> &func) {

  std::lock_guard<std::mutex> lock(mtx);
  std::unique_lock<std::mutex> lockCV(cvMutex);
  using namespace std::chrono_literals;
  std::this_thread::sleep_for(100ms);

  cv.wait(lockCV, [this]() {
    return !(this->completing || this->running || this->settingUp);
  });
  this->settingUp = true;

  for (const auto &subTree : findTrees(this->tree)) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    this->running = true;
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
      assert(!this->completing);
      std::exception_ptr exception = nullptr;
      try {
        subTree->partialParse(this->options.analysisOptions);
      } catch (...) {
        exception = std::current_exception();
      }
      std::map<std::filesystem::path, std::vector<LSPDiagnostic>> ret;

      if (exception) {
        for (const auto &oldDiag : oldDiags) {
          ret[oldDiag] = {};
        }
        func(ret);
        this->tasks.erase(subTree->identifier);
        this->running = false;
        std::rethrow_exception(exception);
        cv.notify_all();
        return;
      }

      const auto &metadata = subTree->metadata;
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
      this->tasks.erase(subTree->identifier);
      this->running = false;
      cv.notify_all();
    });

    this->tasks[identifier] = newTask;
    (void)std::async(std::launch::async, &Task::run, newTask);
    this->settingUp = false;
    return;
  }

  this->settingUp = false;
  cv.notify_one();
}

std::map<std::filesystem::path, std::vector<LSPDiagnostic>>
Workspace::clearDiagnostics() {
  std::map<std::filesystem::path, std::vector<LSPDiagnostic>> ret;

  for (const auto &subTree : findTrees(this->tree)) {
    const auto &metadata = subTree->metadata;
    for (const auto &pair : metadata.diagnostics) {
      if (!ret.contains(pair.first)) {
        ret[pair.first] = {};
      }
    }
  }
  return ret;
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
  this->settingUp = true;
  auto tree = std::make_shared<MesonTree>(this->root, ns);
  tree->fullParse(this->options.analysisOptions,
                  !this->options.neverDownloadAutomatically);
  tree->identifier = this->name;
  this->tree = tree;
  std::map<std::filesystem::path, std::vector<LSPDiagnostic>> ret;
  for (const auto &subTree : findTrees(this->tree)) {
    auto metadata = subTree->metadata;
    if (subTree->depth > 0 &&
        this->options.ignoreDiagnosticsFromSubprojects.has_value()) {
      const auto &toIgnore = this->options.ignoreDiagnosticsFromSubprojects;
      if (toIgnore->empty()) {
        continue; // Skip every subproject
      }
      if (std::find(toIgnore->begin(), toIgnore->end(), subTree->name) !=
          toIgnore->end()) {
        continue;
      }
    }
    for (const auto &pair : metadata.diagnostics) {
      if (!ret.contains(pair.first)) {
        ret[pair.first] = {};
      }
      for (const auto &diag : pair.second) {
        ret[pair.first].push_back(makeLSPDiagnostic(diag));
      }
    }
  }
  this->settingUp = false;
  return ret;
}

std::vector<CompletionItem>
Workspace::completion(const std::filesystem::path &path,
                      const LSPPosition &position) {
  std::unique_lock<std::mutex> lock(mtx);

  cv.wait(lock, [this]() {
    return !this->completing && !this->running && this->tasks.empty() &&
           !this->settingUp;
  });

  this->completing = true;

  for (const auto &subTree : findTrees(this->tree)) {
    auto identifier = subTree->identifier;
    if (this->tasks.contains(identifier)) {
      auto *tsk = this->tasks[identifier];
      this->logger.info(
          std::format("Waiting for {} to terminate", tsk->getUUID()));
      while (tsk->state != TaskState::Ended) {
      }
      this->logger.info(
          std::format("{} finally terminated...", tsk->getUUID()));
    }

    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    cv.wait(lock, [this]() { return !(this->running || this->settingUp); });

    auto ret = complete(path, subTree, subTree->asts[path].back(), position);
    this->completing = false;
    return ret;
  }

  this->completing = false;
  return {};
}
