#pragma once

#include "langserveroptions.hpp"
#include "langserverutils.hpp"
#include "log.hpp"
#include "lsptypes.hpp"
#include "mesontree.hpp"
#include "task.hpp"
#include "typenamespace.hpp"

#include <atomic>
#include <cstdint>
#include <filesystem>
#include <future>
#include <map>
#include <memory>
#include <optional>
#include <semaphore>
#include <string>
#include <vector>

std::vector<MesonTree *> findTrees(const std::shared_ptr<MesonTree> &root);

class Workspace {
public:
  std::filesystem::path root;
  std::string name;
  std::map<std::string /*Identifier*/, std::shared_ptr<Task>> tasks;
  std::map<std::string /*Identifier*/, std::future<void>> futures;
  std::atomic<bool> settingUp = false;
  std::atomic<bool> completing = false;
  std::atomic<bool> running = false;
  std::vector<MesonTree *> foundTrees;
  Logger logger;
  LanguageServerOptions &options;

  Workspace(const WorkspaceFolder &wspf, LanguageServerOptions &options)
      : name(wspf.name), logger("ws-" + wspf.name), options(options) {
    this->root = extractPathFromUrl(wspf.uri);
  }

  std::map<std::filesystem::path, std::vector<LSPDiagnostic>>
  parse(const TypeNamespace &ns);
  std::optional<Hover>
  hover(const std::filesystem::path &path, const LSPPosition &position,
        const std::map<std::string, std::string> &descriptions);
  std::vector<DocumentHighlight> highlight(const std::filesystem::path &path,
                                           const LSPPosition &position);
  std::optional<WorkspaceEdit> rename(const std::filesystem::path &path,
                                      const RenameParams &params);
  std::vector<LSPLocation> jumpTo(const std::filesystem::path &path,
                                  const LSPPosition &position);
  std::vector<CodeAction> codeAction(const std::filesystem::path &path,
                                     const LSPRange &range);
  std::vector<CompletionItem> completion(const std::filesystem::path &path,
                                         const LSPPosition &position,
                                         const std::set<std::string> &pkgNames);

  bool owns(const std::filesystem::path &path);
  std::map<std::filesystem::path, std::vector<LSPDiagnostic>>
  fullReparse(const TypeNamespace &ns);

  template <typename Func>
  void patchFile(const std::filesystem::path &path, const std::string &contents,
                 const Func &func) {
    this->writing.acquire();
    this->reading.acquire();
    this->settingUp = true;

    for (const auto &subTree : this->foundTrees) {
      if (!subTree->ownedFiles.contains(path)) {
        continue;
      }
      this->running = true;
      std::set<std::filesystem::path> oldDiags;
      const auto /*Copy explicitly, as subtree is not valid anymore after
                    parsing*/
          identifier = subTree->identifier;
      for (const auto &[diagPath, _] : subTree->metadata.diagnostics) {
        oldDiags.insert(diagPath);
      }
      subTree->clear();
      subTree->overrides[path] = contents;

      auto newTask = std::make_shared<Task>([&subTree, func, oldDiags, this]() {
        this->update<Func>(subTree, func, oldDiags);
      });

      this->tasks[identifier] = newTask;
      this->settingUp = false;
      futures[identifier] = std::async(std::launch::async, &Task::run, newTask);
      return;
    }

    this->settingUp = false;
  }

  std::vector<InlayHint> inlayHints(const std::filesystem::path &path);
  std::vector<FoldingRange> foldingRanges(const std::filesystem::path &path);
  std::vector<uint64_t> semanticTokens(const std::filesystem::path &path);
  std::vector<SymbolInformation>
  documentSymbols(const std::filesystem::path &path);
  std::optional<std::filesystem::path>
  muonConfigFile(const std::filesystem::path &path);
  void dropCache(const std::filesystem::path &path);
  std::map<std::filesystem::path, std::vector<LSPDiagnostic>>
  clearDiagnostics();

private:
  static std::vector<LSPLocation> jumpTo(const MesonMetadata *metadata,
                                         const std::filesystem::path &path,
                                         const LSPPosition &position);
  static std::vector<LSPLocation>
  jumpToIdentifier(const MesonMetadata *metadata,
                   const std::filesystem::path &path,
                   const LSPPosition &position);
  static std::vector<LSPLocation>
  jumpToFunctionCall(const MesonMetadata *metadata,
                     const std::filesystem::path &path,
                     const LSPPosition &position);
  static WorkspaceEdit rename(const MesonMetadata &metadata,
                              const IdExpression *toRename,
                              const std::string &newName);

  template <typename Func>
  void update(MesonTree *subTree, const Func &func,
              const std::set<std::filesystem::path> &oldDiags) {
    assert(!this->completing);
    std::exception_ptr exception = nullptr;
    try {
      subTree->partialParse(this->options.analysisOptions);
    } catch (...) {
      exception = std::current_exception();
    }

    if (exception) {
      std::map<std::filesystem::path, std::vector<LSPDiagnostic>> ret;
      for (const auto &oldDiag : oldDiags) {
        ret[oldDiag] = {};
      }
      func(ret);
      this->tasks.erase(subTree->identifier);
      this->running = false;
      this->writing.release();
      this->reading.release();
      std::rethrow_exception(exception);
      return;
    }

    std::map<std::filesystem::path, std::set<LSPDiagnostic>> tmp;

    const auto &metadata = subTree->metadata;
    for (const auto &[diagPath, diags] : metadata.diagnostics) {
      if (!tmp.contains(diagPath)) {
        tmp[diagPath] = {};
      }
      for (const auto &diag : diags) {
        tmp[diagPath].insert(makeLSPDiagnostic(diag));
      }
    }
    for (const auto &oldDiag : oldDiags) {
      if (!tmp.contains(oldDiag)) {
        tmp[oldDiag] = {};
      }
    }
    std::map<std::filesystem::path, std::vector<LSPDiagnostic>> ret;
    for (const auto &[path, diags] : tmp) {
      ret[path] = std::vector<LSPDiagnostic>{diags.begin(), diags.end()};
    }
    func(ret);
    this->tasks.erase(subTree->identifier);
    this->foundTrees = findTrees(this->tree);
    this->running = false;
    this->reading.release();
    this->writing.release();
  }

  std::shared_ptr<MesonTree> tree;
  std::binary_semaphore writing{1};
  std::binary_semaphore reading{1};
};
