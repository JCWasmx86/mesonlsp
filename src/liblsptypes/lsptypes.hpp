#pragma once
#include <cassert>
#include <nlohmann/json.hpp>
#include <optional>
#include <string>
#include <utility>
#include <vector> // NOLINT

class BaseObject {
public:
  virtual ~BaseObject() = default;
};

class ClientInfo : public BaseObject {
public:
  std::string name;
  std::optional<std::string> version;

  ClientInfo(nlohmann::json data) {
    this->name = data["name"];
    if (data.contains("version")) {
      this->version = data["version"];
    }
  }
};

class WorkspaceFolder : public BaseObject {
public:
  std::string uri;
  std::string name;

  WorkspaceFolder(nlohmann::json &jsonObj) {
    this->uri = jsonObj["uri"];
    this->name = jsonObj["name"];
  }
};

class ClientCapabilities : public BaseObject {};

enum TextDocumentSyncKind { None = 0, Full = 1, Incremental = 2 };

class SemanticTokensLegend : public BaseObject {
public:
  std::vector<std::string> tokenTypes;
  std::vector<std::string> tokenModifiers;

  SemanticTokensLegend(std::vector<std::string> tokenTypes,
                       std::vector<std::string> tokenModifiers)
      : tokenTypes(std::move(tokenTypes)),
        tokenModifiers(std::move(tokenModifiers)) {}

  nlohmann::json toJson() {
    return {{{"tokenTypes", tokenTypes}, {"tokenModifiers", tokenModifiers}}};
  }
};

class CompletionOptions : public BaseObject {
public:
  std::vector<std::string> triggerCharacters;
  bool resolveProvider;

  CompletionOptions(bool resolveProvider,
                    std::vector<std::string> triggerCharacters)
      : triggerCharacters(std::move(triggerCharacters)),
        resolveProvider(resolveProvider) {}

  nlohmann::json toJson() {
    return {{"triggerCharacters", triggerCharacters},
            {"resolveProvider", resolveProvider}};
  }
};

class SemanticTokensOptions : public BaseObject {
public:
  bool full;
  SemanticTokensLegend legend;

  SemanticTokensOptions(bool full, SemanticTokensLegend legend)
      : full(full), legend(std::move(legend)) {}

  nlohmann::json toJson() {
    return {{"full", full}, {"legend", legend.toJson()}};
  }
};

class TextDocumentSyncOptions : public BaseObject {
public:
  bool openClose;
  TextDocumentSyncKind change;

  TextDocumentSyncOptions(bool openClose, TextDocumentSyncKind change)
      : openClose(openClose), change(change) {}

  nlohmann::json toJson() {
    return {{"openClose", openClose}, {"change", change}};
  }
};

class ServerCapabilities : public BaseObject {
public:
  TextDocumentSyncOptions textDocumentSync;
  bool hoverProvider;
  bool declarationProvider;
  bool definitionProvider;
  bool documentHighlightProvider;
  bool documentSymbolProvider;
  bool codeActionProvider;
  bool documentFormattingProvider;
  bool renameProvider;
  bool foldingRangeProvider;
  bool inlayHintProvider;
  bool diagnosticProvider;
  CompletionOptions completionProvider;
  SemanticTokensOptions semanticTokensProvider;

  // This is stupid
  ServerCapabilities(TextDocumentSyncOptions textDocumentSync,
                     bool hoverProvider, bool declarationProvider,
                     bool definitionProvider, bool documentHighlightProvider,
                     bool documentSymbolProvider, bool codeActionProvider,
                     bool documentFormattingProvider, bool renameProvider,
                     bool foldingRangeProvider, bool inlayHintProvider,
                     bool diagnosticProvider,
                     CompletionOptions completionProvider,
                     SemanticTokensOptions semanticTokensProvider)
      : textDocumentSync(std::move(textDocumentSync)),
        hoverProvider(hoverProvider), declarationProvider(declarationProvider),
        definitionProvider(definitionProvider),
        documentHighlightProvider(documentHighlightProvider),
        documentSymbolProvider(documentSymbolProvider),
        codeActionProvider(codeActionProvider),
        documentFormattingProvider(documentFormattingProvider),
        renameProvider(renameProvider),
        foldingRangeProvider(foldingRangeProvider),
        inlayHintProvider(inlayHintProvider),
        diagnosticProvider(diagnosticProvider),
        completionProvider(std::move(completionProvider)),
        semanticTokensProvider(std::move(semanticTokensProvider)) {}

  nlohmann::json toJson() {
    return {{"textDocumentSync", this->textDocumentSync.toJson()},
            {"hoverProvider", hoverProvider},
            {"definitionProvider", definitionProvider},
            {"declarationProvider", declarationProvider},
            {"documentHighlightProvider", documentHighlightProvider},
            {"documentSymbolProvider", documentSymbolProvider},
            {"codeActionProvider", codeActionProvider},
            {"documentFormattingProvider", documentFormattingProvider},
            {"renameProvider", renameProvider},
            {"foldingRangeProvider", foldingRangeProvider},
            {"inlayHintProvider", inlayHintProvider},
            {"diagnosticProvider", diagnosticProvider},
            {"completionProvider", completionProvider.toJson()},
            {"semanticTokensProvider", semanticTokensProvider.toJson()}};
  }
};

class InitializeParams : public BaseObject {
public:
  std::optional<ClientInfo> clientInfo;
  std::vector<WorkspaceFolder> workspaceFolders;
  std::optional<nlohmann::json> initializationOptions;
  ClientCapabilities capabilities;

  InitializeParams(nlohmann::json &jsonObj) {
    if (jsonObj.contains("clientInfo")) {
      this->clientInfo = ClientInfo(jsonObj["clientInfo"]);
    }
    assert(jsonObj.contains("workspaceFolders"));
    for (auto wsFolder : jsonObj["workspaceFolders"]) {
      this->workspaceFolders.emplace_back(wsFolder);
    }
  }
};

class ServerInfo : public BaseObject {
public:
  std::string name;
  std::string version;

  ServerInfo(std::string name, std::string version)
      : name(std::move(name)), version(std::move(version)) {}

  nlohmann::json toJson() { return {{"json", name}, {"version", version}}; }
};

class InitializeResult : public BaseObject {
public:
  ServerCapabilities capabilities;
  std::optional<ServerInfo> serverInfo;

  InitializeResult(ServerCapabilities capabilities,
                   std::optional<ServerInfo> serverInfo = std::nullopt)
      : capabilities(std::move(capabilities)),
        serverInfo(std::move(serverInfo)) {}

  nlohmann::json toJson() {
    nlohmann::json ret;
    ret["capabilities"] = capabilities.toJson();
    if (serverInfo.has_value()) {
      ret["serverInfo"] = serverInfo->toJson();
    }
    return ret;
  }
};

class InitializedParams : public BaseObject {
public:
  InitializedParams() = default;
};

class TextDocumentItem : public BaseObject {
public:
  std::string uri;
  std::string text;

  TextDocumentItem(nlohmann::json &jsonObj) {
    this->uri = jsonObj["uri"];
    this->text = jsonObj["text"];
  }
};

class DidOpenTextDocumentParams : public BaseObject {
public:
  TextDocumentItem textDocument;

  DidOpenTextDocumentParams(nlohmann::json &jsonObj) : textDocument(jsonObj) {}
};

class TextDocumentIdentifier : public BaseObject {
public:
  std::string uri;

  TextDocumentIdentifier(nlohmann::json &jsonObj) : uri(jsonObj["uri"]) {}
};

class TextDocumentContentChangeEvent : public BaseObject {
public:
  std::string text;

  TextDocumentContentChangeEvent(nlohmann::json &jsonObj)
      : text(jsonObj["text"]) {}
};

class DidChangeTextDocumentParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;
  std::vector<TextDocumentContentChangeEvent> contentChanges;

  DidChangeTextDocumentParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]) {
    for (auto &change : jsonObj["contentChanges"]) {
      contentChanges.emplace_back(change);
    }
  }
};

class DidSaveTextDocumentParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;
  std::string text;

  DidSaveTextDocumentParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]), text(jsonObj["text"]) {}
};

class DidCloseTextDocumentParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;

  DidCloseTextDocumentParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]) {}
};
