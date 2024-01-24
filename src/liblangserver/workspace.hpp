#pragma once

#include "langserveroptions.hpp"
#include "langserverutils.hpp"
#include "log.hpp"
#include "lsptypes.hpp"
#include "task.hpp"
#include "typenamespace.hpp"

#include <atomic>
#include <cstdint>
#include <filesystem>
#include <functional>
#include <future>
#include <map>
#include <memory>
#include <optional>
#include <semaphore>
#include <string>
#include <vector>

class MesonTree;

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
  std::optional<Hover> hover(const std::filesystem::path &path,
                             const LSPPosition &position);
  std::vector<DocumentHighlight> highlight(const std::filesystem::path &path,
                                           const LSPPosition &position);
  std::optional<WorkspaceEdit> rename(const std::filesystem::path &path,
                                      const RenameParams &params);
  std::vector<LSPLocation> jumpTo(const std::filesystem::path &path,
                                  const LSPPosition &position);
  std::vector<CodeAction> codeAction(const std::filesystem::path &path,
                                     const LSPRange &range);
  std::vector<CompletionItem> completion(const std::filesystem::path &path,
                                         const LSPPosition &position);

  bool owns(const std::filesystem::path &path);
  void patchFile(
      const std::filesystem::path &path, const std::string &contents,
      const std::function<void(
          std::map<std::filesystem::path, std::vector<LSPDiagnostic>>)> &func);
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
  static WorkspaceEdit rename(MesonMetadata &metadata,
                              const IdExpression *toRename,
                              const std::string &newName);
  void update(
      MesonTree *subTree,
      const std::function<void(
          std::map<std::filesystem::path, std::vector<LSPDiagnostic>>)> &func,
      const std::set<std::filesystem::path> &oldDiags);
  std::shared_ptr<MesonTree> tree;
  std::binary_semaphore smph{1};
};
