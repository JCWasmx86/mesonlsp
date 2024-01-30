#pragma once

#include "langserveroptions.hpp"
#include "ls.hpp"
#include "lsptypes.hpp"
#include "typenamespace.hpp"
#include "workspace.hpp"

#include <cstdint>
#include <filesystem>
#include <map>
#include <memory>
#include <optional>
#include <semaphore>
#include <set>
#include <string>
#include <vector>

class LanguageServer : public AbstractLanguageServer {
public:
  LanguageServer();
  std::vector<std::shared_ptr<Workspace>> workspaces;
  int inotifyFd{-1};
  std::future<void> inotifyFuture;
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
    this->inotifyFd = -1;
    this->inotifyFuture.wait();
  }

  void setupInotify();

private:
  TypeNamespace ns;
  std::set<std::string> pkgNames;
  LanguageServerOptions options;
  std::binary_semaphore smph{1};
};
