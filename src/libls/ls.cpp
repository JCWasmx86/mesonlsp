#include "ls.hpp"

#include "jsonrpc.hpp"
#include "log.hpp"
#include "lsptypes.hpp"
#include "nlohmann/json.hpp"

#include <exception>
#include <format>
#include <string>
#include <vector>

const static Logger LOG("AbstractLanguageServer"); // NOLINT

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
  if (method == "workspace/didChangeConfiguration") {
    DidChangeConfigurationParams serializedParams(params);
    this->onDidChangeConfiguration(serializedParams);
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
  try {
    nlohmann::json ret;
    if (params.contains("textDocument") &&
        params["textDocument"].contains("uri")) {
      const auto &uri = params["textDocument"]["uri"];
      if (uri.is_string() && !uri.get<std::string>().starts_with("file")) {
        this->server->reply(callId, ret);
        return;
      }
    }
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
    } else if (method == "textDocument/foldingRange") {
      FoldingRangeParams serializedParams(params);
      auto results = this->foldingRanges(serializedParams);
      auto jsonObjects = nlohmann::json::array();
      for (auto &result : results) {
        jsonObjects.push_back(result.toJson());
      }
      ret = jsonObjects;
    } else if (method == "textDocument/semanticTokens/full") {
      SemanticTokensParams serializedParams(params);
      ret = {{"data", this->semanticTokens(serializedParams)}};
    } else if (method == "textDocument/formatting") {
      DocumentFormattingParams serializedParams(params);
      ret = std::vector<nlohmann::json>{
          this->formatting(serializedParams).toJson()};
    } else if (method == "textDocument/documentSymbol") {
      DocumentSymbolParams serializedParams(params);
      auto results = this->documentSymbols(serializedParams);
      auto jsonObjects = nlohmann::json::array();
      for (auto &result : results) {
        jsonObjects.push_back(result.toJson());
      }
      ret = jsonObjects;
    } else if (method == "textDocument/hover") {
      HoverParams serializedParams(params);
      auto result = this->hover(serializedParams);
      if (result.has_value()) {
        ret = result->toJson();
      } else {
        ret = nullptr;
      }
    } else if (method == "textDocument/documentHighlight") {
      DocumentHighlightParams serializedParams(params);
      auto results = this->highlight(serializedParams);
      auto jsonObjects = nlohmann::json::array();
      for (auto &result : results) {
        jsonObjects.push_back(result.toJson());
      }
      ret = jsonObjects;
    } else if (method == "textDocument/rename") {
      RenameParams serializedParams(params);
      auto result = this->rename(serializedParams);
      if (result.has_value()) {
        ret = result->toJson();
      } else {
        ret = nullptr;
      }
    } else if (method == "textDocument/declaration") {
      DeclarationParams serializedParams(params);
      auto results = this->declaration(serializedParams);
      auto jsonObjects = nlohmann::json::array();
      for (auto &result : results) {
        jsonObjects.push_back(result.toJson());
      }
      ret = jsonObjects;
    } else if (method == "textDocument/definition") {
      DefinitionParams serializedParams(params);
      auto results = this->definition(serializedParams);
      auto jsonObjects = nlohmann::json::array();
      for (auto &result : results) {
        jsonObjects.push_back(result.toJson());
      }
      ret = jsonObjects;
    } else if (method == "textDocument/codeAction") {
      CodeActionParams serializedParams(params);
      auto results = this->codeAction(serializedParams);
      auto jsonObjects = nlohmann::json::array();
      for (auto &result : results) {
        jsonObjects.push_back(result.toJson());
      }
      ret = jsonObjects;
    } else if (method == "textDocument/completion") {
      CompletionParams serializedParams(params);
      auto results = this->completion(serializedParams);
      auto jsonObjects = nlohmann::json::array();
      for (auto &result : results) {
        jsonObjects.push_back(result.toJson());
      }
      ret = jsonObjects;
    } else {
      LOG.warn(std::format("Unknown request: '{}'", method));
      this->server->returnError(callId, jsonrpc::JsonrpcError::METHOD_NOT_FOUND,
                                std::format("Unknown request: {}", method));
      return;
    }
    this->server->reply(callId, ret);
  } catch (const std::string &str) {
    this->server->returnError(callId, jsonrpc::JsonrpcError::INTERNAL_ERROR,
                              str);
  } catch (const char *str) {
    this->server->returnError(callId, jsonrpc::JsonrpcError::INTERNAL_ERROR,
                              str);
  } catch (const std::exception &exc) {
    this->server->returnError(callId, jsonrpc::JsonrpcError::INTERNAL_ERROR,
                              exc.what());
  } catch (...) {
    LOG.error("Something else was caught");
    this->server->returnError(callId, jsonrpc::JsonrpcError::INTERNAL_ERROR,
                              "No idea what happened");
  }
}
