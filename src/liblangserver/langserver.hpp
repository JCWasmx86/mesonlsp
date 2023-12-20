#pragma once

#include "ls.hpp"

class LanguageServer : public AbstractLanguageServer {
public:
  InitializeResult initialize(InitializeParams &params) override;
  void shutdown() override;

  void onInitialized(InitializedParams &params) override;
  void onExit() override;
  void onDidOpenTextDocument(DidOpenTextDocumentParams &params) override;
  void onDidChangeTextDocument(DidChangeTextDocumentParams &params) override;
  void onDidSaveTextDocument(DidSaveTextDocumentParams &params) override;
  void onDidCloseTextDocument(DidCloseTextDocumentParams &params) override;

  ~LanguageServer() {}
};
