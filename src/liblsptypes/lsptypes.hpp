#pragma once
#include <nlohmann/json.hpp>
#include <optional>
#include <string>
#include <vector>

class BaseObject {
public:
  BaseObject(nlohmann::json jsonObj);
  virtual ~BaseObject() = default;
};

class ClientInfo : public BaseObject {
public:
  std::string name;
  std::optional<std::string> version;
};

class WorkspaceFolder : public BaseObject {
public:
  std::string uri;
  std::string name;
};

class ClientCapabilities : public BaseObject {};

enum TextDocumentSyncKind { None = 0, Full = 1, Incremental = 2 };

class ServerCapabilities : public BaseObject {
public:
  TextDocumentSyncKind textDocumentSync;
};

class InitializeParams : public BaseObject {
public:
  std::optional<ClientInfo> clientInfo;
  std::vector<WorkspaceFolder> workspaceFolders;
  std::optional<nlohmann::json> initializationOptions;
  ClientCapabilities capabilities;
};

class ServerInfo : public BaseObject {
public:
  std::string name;
  std::optional<std::string> version;
};

class InitializeResult : public BaseObject {
public:
  ServerCapabilities capabilities;
  std::optional<ServerInfo> serverInfo;
};

class TextDocumentItem : public BaseObject {
  std::string uri;
  std::string text;
};

class DidOpenTextDocumentParams : public BaseObject {
public:
  TextDocumentItem textDocument;
};

class TextDocumentIdentifier : public BaseObject {
public:
  std::string uri;
};

class TextDocumentContentChangeEvent : public BaseObject {
public:
  std::string text;
};

class DidChangeTextDocumentParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;
  std::vector<TextDocumentContentChangeEvent> contentChanges;
};

class DidSaveTextDocumentParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;
  std::optional<std::string> text;
};

class DidCloseTextDocumentParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;
};
