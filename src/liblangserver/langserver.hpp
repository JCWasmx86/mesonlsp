#pragma once

#include "langserveroptions.hpp"
#include "ls.hpp"
#include "lsptypes.hpp"
#include "typenamespace.hpp"
#include "workspace.hpp"

#include <cstdint>
#include <cstdlib>
#include <ctime>
#include <filesystem>
#include <map>
#include <memory>
#include <optional>
#include <semaphore>
#include <set>
#include <string>
#include <vector>

#if __has_include(<sys/inotify.h>)
#define HAS_INOTIFY
#endif
void printGreeting();

class LanguageServer : public AbstractLanguageServer {
public:
  LanguageServer() {
    srand(time(nullptr));
    this->initPkgNames();
    printGreeting();
  }

  void initPkgNames();
  std::vector<std::shared_ptr<Workspace>> workspaces;
#ifdef HAS_INOTIFY
  std::atomic<int> inotifyFd{-1};
  std::future<void> inotifyFuture;
#endif
  std::map<std::filesystem::path, std::string> cachedContents;
  std::vector<std::map<std::filesystem::path, std::vector<LSPDiagnostic>>>
      diagnosticsFromInitialisation;

  InitializeResult initialize(InitializeParams &params) override;
  std::vector<InlayHint> inlayHints(InlayHintParams &params) override;
  std::vector<FoldingRange> foldingRanges(FoldingRangeParams &params) override;
  std::vector<uint64_t> semanticTokens(SemanticTokensParams &params) override;
  TextEdit formatting(DocumentFormattingParams &params) override;
  std::vector<SymbolInformation>
  documentSymbols(DocumentSymbolParams &params) override;
  std::optional<Hover> hover(HoverParams &params) override;
  std::vector<DocumentHighlight>
  highlight(DocumentHighlightParams &params) override;
  std::optional<WorkspaceEdit> rename(RenameParams &params) override;
  std::vector<LSPLocation> declaration(DeclarationParams &params) override;
  std::vector<LSPLocation> definition(DefinitionParams &params) override;
  std::vector<CodeAction> codeAction(CodeActionParams &params) override;
  std::vector<CompletionItem> completion(CompletionParams &params) override;
  void shutdown() override;
  void watch(std::map<std::filesystem::path, int> fds);

  void onInitialized(InitializedParams & /*params*/) override;
  void onExit() override;
  void onDidOpenTextDocument(DidOpenTextDocumentParams &params) override;
  void onDidChangeConfiguration(DidChangeConfigurationParams &params) override;
  void onDidChangeTextDocument(DidChangeTextDocumentParams &params) override;
  void onDidSaveTextDocument(DidSaveTextDocumentParams &params) override;
  void onDidCloseTextDocument(DidCloseTextDocumentParams &params) override;
  void fullReparse(const std::filesystem::path &path);

  void publishDiagnostics(const std::map<std::filesystem::path,
                                         std::vector<LSPDiagnostic>> &newDiags);

  ~LanguageServer() override {
#ifdef HAS_INOTIFY
    this->inotifyFd = -1;
    this->inotifyFuture.wait();
#endif
  }
#ifdef HAS_INOTIFY
  void setupInotify();
#endif

private:
  TypeNamespace ns;
  std::set<std::string> pkgNames;
  std::map<std::string, std::string> descriptions;
  LanguageServerOptions options;
  std::binary_semaphore smph{1};
};
