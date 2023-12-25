#include "langserver.hpp"

#include "langserverutils.hpp"
#include "log.hpp"
#include "lsptypes.hpp"
#include "workspace.hpp"

static Logger LOG("LanguageServer"); // NOLINT

InitializeResult LanguageServer::initialize(InitializeParams &params) {
  for (auto wspf : params.workspaceFolders) {
    auto workspace = std::make_shared<Workspace>(wspf);
    auto diags = workspace->parse(this->ns);
    this->diagnosticsFromInitialisation.emplace_back(diags);
    this->workspaces.push_back(workspace);
  }
  return {ServerCapabilities(
              TextDocumentSyncOptions(true, TextDocumentSyncKind::Full), true,
              true, true, true, true, true, true, true, true, true, true,
              CompletionOptions(false, {".", "_"}),
              SemanticTokensOptions(
                  true, SemanticTokensLegend({"substitute", "substitute_bounds",
                                              "variable", "function", "method",
                                              "keyword", "string", "number"},
                                             {"readonly", "defaultLibrary"}))),
          ServerInfo("c++-mesonlsp", VERSION)};
}

void LanguageServer::shutdown() {}

void LanguageServer::onInitialized(InitializedParams & /*params*/) {
  for (const auto &map : this->diagnosticsFromInitialisation) {
    this->publishDiagnostics(map);
  }
  this->diagnosticsFromInitialisation.clear();
}

void LanguageServer::onExit() {}

void LanguageServer::onDidOpenTextDocument(DidOpenTextDocumentParams &params) {}

void LanguageServer::onDidChangeTextDocument(
    DidChangeTextDocumentParams &params) {
  auto path = extractPathFromUrl(params.textDocument.uri);
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      LOG.info(std::format("Patching file {} for workspace {}",
                           path.generic_string(), workspace->name));
      workspace->patchFile(
          path, params.contentChanges[0].text,
          [this](
              const std::map<std::filesystem::path, std::vector<LSPDiagnostic>>
                  &changes) { this->publishDiagnostics(changes); });
      return;
    }
  }
}

std::vector<InlayHint> LanguageServer::inlayHints(InlayHintParams &params) {
  auto path = extractPathFromUrl(params.textDocument.uri);
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->inlayHints(path);
    }
  }
  return {};
}

std::vector<uint64_t>
LanguageServer::semanticTokens(SemanticTokensParams &params) {
  auto path = extractPathFromUrl(params.textDocument.uri);
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->semanticTokens(path);
    }
  }
  return {};
}

std::vector<FoldingRange>
LanguageServer::foldingRanges(FoldingRangeParams &params) {
  auto path = extractPathFromUrl(params.textDocument.uri);
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->foldingRanges(path);
    }
  }
  return {};
}

void LanguageServer::onDidSaveTextDocument(DidSaveTextDocumentParams &params) {}

void LanguageServer::onDidCloseTextDocument(
    DidCloseTextDocumentParams &params) {}

void LanguageServer::publishDiagnostics(
    std::map<std::filesystem::path, std::vector<LSPDiagnostic>> newDiags) {
  for (const auto &pair : newDiags) {
    auto asURI = pathToUrl(pair.first);
    auto clearingParams = PublishDiagnosticsParams(asURI, {});
    this->server->notification("textDocument/publishDiagnostics",
                               clearingParams.toJson());
    auto newParams = PublishDiagnosticsParams(asURI, pair.second);
    this->server->notification("textDocument/publishDiagnostics",
                               newParams.toJson());
    LOG.info(std::format("Publishing {} diagnostics for {}", pair.second.size(),
                         pair.first.generic_string()));
  }
}
