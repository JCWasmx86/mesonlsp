#pragma once

#include "ls.hpp"
#include "lsptypes.hpp"
#include "typenamespace.hpp"
#include "workspace.hpp"

#include <cstdint>
#include <filesystem>
#include <map>
#include <memory>
#include <optional>
#include <string>
#include <vector>

class LanguageServer : public AbstractLanguageServer {
public:
  std::vector<std::shared_ptr<Workspace>> workspaces;
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
  void shutdown() override;

  void onInitialized(InitializedParams & /*params*/) override;
  void onExit() override;
  void onDidOpenTextDocument(DidOpenTextDocumentParams &params) override;
  void onDidChangeTextDocument(DidChangeTextDocumentParams &params) override;
  void onDidSaveTextDocument(DidSaveTextDocumentParams &params) override;
  void onDidCloseTextDocument(DidCloseTextDocumentParams &params) override;

  void publishDiagnostics(const std::map<std::filesystem::path,
                                         std::vector<LSPDiagnostic>> &newDiags);

  ~LanguageServer() override = default;

private:
  TypeNamespace ns;
};
