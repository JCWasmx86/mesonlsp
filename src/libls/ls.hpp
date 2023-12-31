#pragma once
#include "jsonrpc.hpp"
#include "lsptypes.hpp"

#include <cstdint>
#include <nlohmann/json.hpp>
#include <optional>
#include <string>
#include <vector>

class AbstractLanguageServer : public jsonrpc::JsonRpcHandler {
public:
  void handleNotification(std::string method, nlohmann::json params) override;
  void handleRequest(std::string method, nlohmann::json callId,
                     nlohmann::json params) override;

  virtual InitializeResult initialize(InitializeParams &params) = 0;
  virtual std::vector<InlayHint> inlayHints(InlayHintParams &params) = 0;
  virtual std::vector<FoldingRange>
  foldingRanges(FoldingRangeParams &params) = 0;
  virtual std::vector<uint64_t>
  semanticTokens(SemanticTokensParams &params) = 0;
  virtual TextEdit formatting(DocumentFormattingParams &params) = 0;
  virtual std::vector<SymbolInformation>
  documentSymbols(DocumentSymbolParams &params) = 0;
  virtual std::optional<Hover> hover(HoverParams &params) = 0;
  virtual std::vector<DocumentHighlight>
  highlight(DocumentHighlightParams &params) = 0;
  virtual std::optional<WorkspaceEdit> rename(RenameParams &params) = 0;
  virtual std::vector<LSPLocation> declaration(DeclarationParams &params) = 0;
  virtual std::vector<LSPLocation> definition(DefinitionParams &params) = 0;
  virtual std::vector<CodeAction> codeAction(CodeActionParams &params) = 0;
  virtual std::vector<CompletionItem> completion(CompletionParams &params) = 0;
  virtual void shutdown() = 0;

  virtual void onInitialized(InitializedParams &params) = 0;
  virtual void onExit() = 0;
  virtual void
  onDidChangeConfiguration(DidChangeConfigurationParams &params) = 0;
  virtual void onDidOpenTextDocument(DidOpenTextDocumentParams &params) = 0;
  virtual void onDidChangeTextDocument(DidChangeTextDocumentParams &params) = 0;
  virtual void onDidSaveTextDocument(DidSaveTextDocumentParams &params) = 0;
  virtual void onDidCloseTextDocument(DidCloseTextDocumentParams &params) = 0;
};
