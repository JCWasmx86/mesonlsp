#include "ls.hpp"

#include "jsonrpc.hpp"
#include "log.hpp"
#include "lsptypes.hpp"
#include "nlohmann/json.hpp"

#include <format>

static Logger LOG("AbstractLanguageServer"); // NOLINT

void AbstractLanguageServer::handleNotification(std::string method,
                                                nlohmann::json params) {
  LOG.info(std::format("Received notification {}", method));
  if (method == "initialized") {
    InitializedParams serializedParams;
    this->onInitialized(serializedParams);
    return;
  }
  if (method == "textDocument/didOpen") {
    DidOpenTextDocumentParams serializedParams(params);
    this->onDidOpenTextDocument(serializedParams);
    return;
  }
  if (method == "textDocument/didClose") {
    DidCloseTextDocumentParams serializedParams(params);
    this->onDidCloseTextDocument(serializedParams);
    return;
  }
  if (method == "textDocument/didChange") {
    DidChangeTextDocumentParams serializedParams(params);
    this->onDidChangeTextDocument(serializedParams);
    return;
  }
  if (method == "textDocument/didSave") {
    DidSaveTextDocumentParams serializedParams(params);
    this->onDidSaveTextDocument(serializedParams);
    return;
  }
  if (method == "exit") {
    this->onExit();
    return;
  }
  LOG.warn(std::format("Unknown notification: '{}'", method));
}

void AbstractLanguageServer::handleRequest(std::string method,
                                           nlohmann::json callId,
                                           nlohmann::json params) {
  LOG.info(std::format("Received request: {}", method));
  nlohmann::json ret;
  if (method == "initialize") {
    InitializeParams serializedParams(params);
    auto results = this->initialize(serializedParams);
    ret = results.toJson();
  } else if (method == "textDocument/inlayHint") {
    InlayHintParams serializedParams(params);
    auto results = this->inlayHints(serializedParams);
    auto jsonObjects = nlohmann::json::array();
    for (auto &result : results) {
      jsonObjects.push_back(result.toJson());
    }
    ret = jsonObjects;
  } else {
    LOG.warn(std::format("Unknown request: '{}'", method));
    this->server->returnError(jsonrpc::JsonrpcError::MethodNotFound,
                              std::format("Unknown request: {}", method));
    return;
  }
  this->server->reply(callId, ret);
}
