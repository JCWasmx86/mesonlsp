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
#include <atomic>
#include <cassert>
#include <cstddef>
#include <cstdint>
#include <exception>
#include <filesystem>
#include <format>
#include <functional>
#include <future>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <string>
#include <vector>

std::vector<MesonTree *> findTrees(const std::shared_ptr<MesonTree> &root) {
  std::vector<MesonTree *> ret;
  ret.emplace_back(root.get());
  for (const auto &subproj : root->state->subprojects) {
    if (subproj->tree) {
      auto recursiveTrees = findTrees(subproj->tree);
      ret.insert(ret.end(), recursiveTrees.begin(), recursiveTrees.end());
    }
  }
  return ret;
}

bool Workspace::owns(const std::filesystem::path &path) {
  this->smph.acquire();
  for (const auto &subTree : this->foundTrees) {
    if (subTree->ownedFiles.contains(path)) {
      this->smph.release();
      return true;
    }
  }
  this->smph.release();
  return false;
}

std::vector<InlayHint>
Workspace::inlayHints(const std::filesystem::path &path) {
  this->smph.acquire();
  for (const auto &subTree : this->foundTrees) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto ast = subTree->asts[path];
    if (ast.empty()) {
      continue;
    }
    auto visitor = InlayHintVisitor();
    ast.back()->visit(&visitor);
    this->smph.release();
    return visitor.hints;
  }
  this->smph.release();
  return {};
}

std::optional<Hover> Workspace::hover(const std::filesystem::path &path,
                                      const LSPPosition &position) {
  this->smph.acquire();
  for (const auto &subTree : this->foundTrees) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto metadata = subTree->metadata;
    auto feOpt = metadata.findFunctionExpressionAt(path, position.line,
                                                   position.character);
    if (feOpt.has_value()) {
      auto val =
          makeHoverForFunctionExpression(feOpt.value(), subTree->options);
      this->smph.release();
      return val;
    }
    auto meOpt = metadata.findMethodExpressionAt(path, position.line,
                                                 position.character);
    if (meOpt.has_value()) {
      auto val = makeHoverForMethodExpression(meOpt.value());
      this->smph.release();
      return val;
    }
    auto idExprOpt =
        metadata.findIdExpressionAt(path, position.line, position.character);
    if (idExprOpt.has_value()) {
      auto val = makeHoverForId(idExprOpt.value());
      this->smph.release();
      return val;
    }
    this->smph.release();
    return {};
  }
  this->smph.release();
  return std::nullopt;
}

std::vector<CodeAction> Workspace::codeAction(const std::filesystem::path &path,
                                              const LSPRange &range) {
  this->smph.acquire();
  for (const auto &subTree : this->foundTrees) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto ast = subTree->asts[path];
    if (ast.empty()) {
      continue;
    }
    auto visitor = CodeActionVisitor(range, pathToUrl(path), subTree);
    ast.back()->visit(&visitor);
    this->smph.release();
    return visitor.actions;
  }
  this->smph.release();
  return {};
}

std::vector<DocumentHighlight>
Workspace::highlight(const std::filesystem::path &path,
                     const LSPPosition &position) {
  this->smph.acquire();
  for (const auto &subTree : this->foundTrees) {
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
      this->smph.release();
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
      const auto loc = toCheck->location;
      auto range = LSPRange(LSPPosition(loc.startLine, loc.startColumn),
                            LSPPosition(loc.endLine, loc.endColumn));
      ret.emplace_back(range, kind);
    }
    this->smph.release();
    return ret;
  }
  this->smph.release();
  return {};
}

std::vector<uint64_t>
Workspace::semanticTokens(const std::filesystem::path &path) {
  this->smph.acquire();
  for (const auto &subTree : this->foundTrees) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto ast = subTree->asts[path];
    if (ast.empty()) {
      continue;
    }
    auto visitor = SemanticTokensVisitor();
    ast.back()->visit(&visitor);
    this->smph.release();
    return visitor.finish();
  }
  this->smph.release();
  return {};
}

std::vector<LSPLocation> Workspace::jumpTo(const std::filesystem::path &path,
                                           const LSPPosition &position) {
  this->smph.acquire();
  for (const auto &subTree : this->foundTrees) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    const auto &metadata = &subTree->metadata;
    auto foundMyself = false;
    std::string toFind;
    for (size_t i = metadata->encounteredIds.size() - 1; i >= 0; i--) {
      if (i == (size_t)-1) {
        break;
      }
      const auto &idExpr = metadata->encounteredIds[i];
      if (idExpr->file->file == path &&
          MesonMetadata::contains(idExpr, position.line, position.character)) {
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
          const auto loc = idExpr->location;
          auto range = LSPRange(LSPPosition(loc.startLine, loc.startColumn),
                                LSPPosition(loc.endLine, loc.endColumn));
          this->smph.release();
          return {LSPLocation(pathToUrl(idExpr->file->file), range)};
        }
      }
      if (dynamic_cast<IterationStatement *>(idExpr->parent)) {
        const auto loc = idExpr->location;
        auto range = LSPRange(LSPPosition(loc.startLine, loc.startColumn),
                              LSPPosition(loc.endLine, loc.endColumn));
        this->smph.release();
        return {LSPLocation(pathToUrl(idExpr->file->file), range)};
      }
    }
    if (!metadata->functionCalls.contains(path)) {
      this->smph.release();
      return {};
    }
    for (const auto &funcCall : metadata->functionCalls.at(path)) {
      if (!MesonMetadata::contains(funcCall, position.line,
                                   position.character) ||
          funcCall->file->file != path) {
        continue;
      }
      if (funcCall->functionName() != "subdir") {
        this->smph.release();
        return {};
      }
      auto key = std::format("{}-{}", funcCall->file->file.generic_string(),
                             funcCall->location.format());
      if (!metadata->subdirCalls.contains(key)) {
        this->smph.release();
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
      this->smph.release();
      return ret;
    }
    break;
  }
  this->smph.release();
  return {};
}

std::optional<WorkspaceEdit>
Workspace::rename(const std::filesystem::path &path,
                  const RenameParams &params) {
  this->smph.acquire();
  for (const auto &subTree : this->foundTrees) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto metadata = subTree->metadata;
    auto toRenameOpt = metadata.findIdExpressionAt(path, params.position.line,
                                                   params.position.character);
    if (!toRenameOpt.has_value()) {
      this->smph.release();
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
        const auto loc = identifier->location;
        auto range = LSPRange(LSPPosition(loc.startLine, loc.startColumn),
                              LSPPosition(loc.endLine, loc.endColumn));
        // TODO: Rename parent-project `get_variable`
        ret.changes[url].emplace_back(range, params.newName);
      }
    }
    this->smph.release();
    return ret;
  }
  this->smph.release();
  return std::nullopt;
}

std::vector<FoldingRange>
Workspace::foldingRanges(const std::filesystem::path &path) {
  this->smph.acquire();
  for (const auto &subTree : this->foundTrees) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto ast = subTree->asts[path];
    if (ast.empty()) {
      continue;
    }
    auto visitor = FoldingRangeVisitor();
    ast.back()->visit(&visitor);
    this->smph.release();
    return visitor.ranges;
  }
  this->smph.release();
  return {};
}

std::vector<SymbolInformation>
Workspace::documentSymbols(const std::filesystem::path &path) {
  this->smph.acquire();
  for (const auto &subTree : this->foundTrees) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto ast = subTree->asts[path];
    if (ast.empty()) {
      continue;
    }
    auto visitor = DocumentSymbolVisitor();
    ast.back()->visit(&visitor);
    this->smph.release();
    return visitor.symbols;
  }
  this->smph.release();
  return {};
}

void Workspace::dropCache(const std::filesystem::path &path) {
  for (const auto &subTree : this->foundTrees) {
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
  this->smph.acquire();
  this->settingUp = true;

  for (const auto &subTree : this->foundTrees) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    this->running = true;
    std::set<std::filesystem::path> oldDiags;
    auto identifier = subTree->identifier;
    for (const auto &pair : subTree->metadata.diagnostics) {
      oldDiags.insert(pair.first);
    }
    subTree->clear();
    subTree->overrides[path] = contents;

    auto *newTask = new Task([&subTree, func, oldDiags, this]() {
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
        this->smph.release();
        std::rethrow_exception(exception);
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
      this->foundTrees = findTrees(this->tree);
      this->running = false;
      this->smph.release();
    });

    this->tasks[identifier] = newTask;
    this->settingUp = false;
    futures[identifier] = std::async(std::launch::async, &Task::run, newTask);
    return;
  }

  this->settingUp = false;
}

std::map<std::filesystem::path, std::vector<LSPDiagnostic>>
Workspace::clearDiagnostics() {
  std::map<std::filesystem::path, std::vector<LSPDiagnostic>> ret;

  for (const auto &subTree : this->foundTrees) {
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
  for (const auto &tree : this->foundTrees) {
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
  this->foundTrees = findTrees(this->tree);
  std::map<std::filesystem::path, std::vector<LSPDiagnostic>> ret;
  for (const auto &subTree : this->foundTrees) {
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
  this->smph.acquire();
  this->completing = true;

  for (const auto &subTree : this->foundTrees) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto ret = complete(path, subTree, subTree->asts[path].back(), position);
    this->completing = false;
    this->smph.release();
    return ret;
  }

  this->completing = false;
  this->smph.release();
  return {};
}
