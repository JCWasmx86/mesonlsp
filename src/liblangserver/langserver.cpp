#include "langserver.hpp"

#include "lsptypes.hpp"

InitializeResult LanguageServer::initialize(InitializeParams &params) {
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

void LanguageServer::onInitialized(InitializedParams &params) {}

void LanguageServer::onExit() {}

void LanguageServer::onDidOpenTextDocument(DidOpenTextDocumentParams &params) {}

void LanguageServer::onDidChangeTextDocument(
    DidChangeTextDocumentParams &params) {}

void LanguageServer::onDidSaveTextDocument(DidSaveTextDocumentParams &params) {}

void LanguageServer::onDidCloseTextDocument(
    DidCloseTextDocumentParams &params) {}
