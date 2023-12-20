#pragma once
#include <cassert>
#include <nlohmann/json.hpp>
#include <optional>
#include <string>
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

class ClientCapabilities : public BaseObject {
public:
  ClientCapabilities(nlohmann::json &jsonObj) {}
};

enum TextDocumentSyncKind { None = 0, Full = 1, Incremental = 2 };

class ServerCapabilities : public BaseObject {
public:
  TextDocumentSyncKind textDocumentSync;

  nlohmann::json toJson() {
    return {"textDocumentSync", this->textDocumentSync};
  }
};

class InitializeParams : public BaseObject {
public:
  std::optional<ClientInfo> clientInfo;
  std::vector<WorkspaceFolder> workspaceFolders;
  std::optional<nlohmann::json> initializationOptions;
  ClientCapabilities capabilities;

  InitializeParams(nlohmann::json &jsonObj)
      : capabilities(jsonObj["capabilities"]) {
    if (jsonObj.contains("clientInfo")) {
      this->clientInfo = ClientInfo(jsonObj["clientInfo"]);
    }
    assert(jsonObj.contains("workspaceFolders"));
    for (auto wsFolder : jsonObj["workspaceFolders"]) {
      this->workspaceFolders.push_back(wsFolder);
    }
  }
};

class ServerInfo : public BaseObject {
public:
  std::string name;
  std::string version;

  nlohmann::json toJson() { return {{"json", name}, {"version", version}}; }
};

class InitializeResult : public BaseObject {
public:
  ServerCapabilities capabilities;
  std::optional<ServerInfo> serverInfo;

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
  InitializedParams() {}
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
