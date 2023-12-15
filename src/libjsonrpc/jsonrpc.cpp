#include "jsonrpc.hpp"
#include <cstddef>
#include <cstdio>
#include <format>
#include <future>
#include <memory>
#include <mutex>
#include <nlohmann/json.hpp>
#include <string>
#include <utility>

void jsonrpc::JsonRpcServer::evaluateData(
    std::shared_ptr<jsonrpc::JsonRpcHandler> handler, nlohmann::json data) {
  if (!data.contains("jsonrpc")) {
    this->returnError(JsonrpcError::ParseError, "Missing jsonrpc key");
    return;
  }
  if (!data["jsonrpc"].is_string()) {
    this->returnError(JsonrpcError::ParseError, "jsonrpc key is not a string");
    return;
  }
  std::string version = data["jsonrpc"];
  if (version != "2.0") {
    this->returnError(JsonrpcError::ParseError, "jsonrpc is not \"2.0\"");
    return;
  }
  if (!data.contains("method")) {
    this->returnError(JsonrpcError::ParseError, "Missing method key");
    return;
  }
  if (!data["method"].is_string()) {
    this->returnError(JsonrpcError::ParseError, "method key is not a string");
    return;
  }
  std::string method = data["method"];
  nlohmann::json params = data.contains("params") ? data["params"] : nullptr;
  if (data.contains("id")) {
    auto callId = data["id"];
    if (this->shouldExit) {
      return;
    }
    auto future = std::async(std::launch::async, &JsonRpcHandler::handleRequest,
                             handler, method, callId, params);
    this->futures.push_back(std::move(future));
  } else {
    if (this->shouldExit) {
      return;
    }
    auto future =
        std::async(std::launch::async, &JsonRpcHandler::handleNotification,
                   handler, method, params);
    this->futures.push_back(std::move(future));
  }
}

void jsonrpc::JsonRpcServer::sendToClient(nlohmann::json data) {
  std::lock_guard<std::mutex> guard(this->output_mutex);
  std::string payload = data.dump();
  auto len = payload.size();
  auto fullMessage = std::format("Content-Length:{}\r\n\r\n{}", len, payload);
  this->output.write(fullMessage.data(), fullMessage.size());
}

void jsonrpc::JsonRpcServer::reply(nlohmann::json callId,
                                   nlohmann::json result) {
  nlohmann::json data;
  data["jsonrpc"] = "2.0";
  data["id"] = callId;
  data["result"] = result;
  this->sendToClient(data);
}

void jsonrpc::JsonRpcServer::returnError(JsonrpcError error,
                                         std::string message) {
  nlohmann::json err;
  err["code"] = error;
  err["message"] = message;
  nlohmann::json data;
  data["jsonrpc"] = "2.0";
  data["error"] = err;
  data["id"] = nullptr;
  this->sendToClient(data);
}

void jsonrpc::JsonRpcServer::notification(std::string method,
                                          nlohmann::json params) {
  nlohmann::json data;
  data["jsonrpc"] = "2.0";
  data["method"] = method;
  data["params"] = params;
  this->sendToClient(data);
}

void jsonrpc::JsonRpcServer::loop(
    std::shared_ptr<jsonrpc::JsonRpcHandler> handler) {
  std::string prefix = "Content-Length:";
  while (true) {
    auto state = 0;
    auto contentLength = 0;
    auto breakFromLoop = false;
    std::string header;

    while (!breakFromLoop) {
      auto ch = this->input.get();
      if (ch == EOF) {
        return;
      }
      switch (ch) {
      case '\r':
        state = state == 2 ? 3 : 1;
        break;
      case '\n':
        if (state == 3) {
          breakFromLoop = true;
          break;
        }
        state = 2;
        if (header.starts_with(prefix)) {
          auto numberAsStr = header.substr(prefix.length());
          contentLength = std::stoi(numberAsStr);
        }
        break;
      default:
        header += (char)ch;
        state = 5;
      }
      if (breakFromLoop) {
        break;
      }
    }
    if (this->shouldExit) {
      return;
    }
    std::string messageData;
    if (this->shouldExit) {
      return;
    }
    // TODO: Efficiency!
    for (int i = 0; i < contentLength; i++) {
      messageData += (char)this->input.get();
    }
    try {
      auto data = nlohmann::json::parse(messageData);
      this->evaluateData(handler, data);
    } catch (nlohmann::json::parse_error &ex) {
      this->returnError(JsonrpcError::ParseError, "Invalid JSON");
    }
  }
}

void jsonrpc::JsonRpcServer::exit() { this->shouldExit = true; }

jsonrpc::JsonRpcHandler::JsonRpcHandler() {}

void jsonrpc::JsonRpcServer::wait() {
  for (size_t i = 0; i < this->futures.size(); i++) {
    this->futures[i].get();
  }
}
