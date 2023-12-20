#include "langserver.hpp"

#include "lsptypes.hpp"

InitializeResult LanguageServer::initialize(InitializeParams &params) {
  return {ServerCapabilities(TextDocumentSyncKind::Full),
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
