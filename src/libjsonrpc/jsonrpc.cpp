#include "jsonrpc.hpp"

#include "polyfill.hpp"

#include <cstdio>
#include <future>
#include <memory>
#include <mutex>
#include <nlohmann/json.hpp>
#include <string>
#include <utility>

void jsonrpc::JsonRpcServer::evaluateData(
    const std::shared_ptr<jsonrpc::JsonRpcHandler> &handler,
    nlohmann::json data) {
  if (!data.contains("jsonrpc")) {
    this->returnError(nullptr, JsonrpcError::PARSE_ERROR,
                      "Missing jsonrpc key");
    return;
  }
  if (!data["jsonrpc"].is_string()) {
    this->returnError(nullptr, JsonrpcError::PARSE_ERROR,
                      "jsonrpc key is not a string");
    return;
  }
  std::string const version = data["jsonrpc"];
  if (version != "2.0") {
    this->returnError(nullptr, JsonrpcError::PARSE_ERROR,
                      "jsonrpc is not \"2.0\"");
    return;
  }
  if (!data.contains("method")) {
    this->returnError(nullptr, JsonrpcError::PARSE_ERROR, "Missing method key");
    return;
  }
  if (!data["method"].is_string()) {
    this->returnError(nullptr, JsonrpcError::PARSE_ERROR,
                      "method key is not a string");
    return;
  }
  std::string const method = data["method"];
  nlohmann::json const params =
      data.contains("params") ? data["params"] : nullptr;
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

void jsonrpc::JsonRpcServer::sendToClient(const nlohmann::json &data) {
  std::scoped_lock<std::mutex> const guard(this->output_mutex);
  std::string payload = data.dump();
  auto len = payload.size();
  auto fullMessage = std::format("Content-Length: {}\r\n\r\n{}", len, payload);
  this->output.write(fullMessage.data(), (long)fullMessage.size());
  this->output.flush();
}

void jsonrpc::JsonRpcServer::reply(nlohmann::json callId,
                                   nlohmann::json result) {
  nlohmann::json data;
  data["jsonrpc"] = "2.0";
  data["id"] = std::move(callId);
  data["result"] = std::move(result);
  this->sendToClient(data);
}

void jsonrpc::JsonRpcServer::returnError(nlohmann::json callId,
                                         JsonrpcError error,
                                         const std::string &message) {
  nlohmann::json err;
  err["code"] = error;
  err["message"] = message;
  nlohmann::json data;
  data["jsonrpc"] = "2.0";
  data["error"] = err;
  data["id"] = std::move(callId);
  this->sendToClient(data);
}

void jsonrpc::JsonRpcServer::notification(const std::string &method,
                                          nlohmann::json params) {
  nlohmann::json data;
  data["jsonrpc"] = "2.0";
  data["method"] = method;
  data["params"] = std::move(params);
  this->sendToClient(data);
}

enum class JsonrpcState {
  INITIAL = 0,
  FIRST_R = 1,
  FIRST_N = 2,
  SECOND_R = 3,
  READING = 4
};

void jsonrpc::JsonRpcServer::loop(
    const std::shared_ptr<jsonrpc::JsonRpcHandler> &handler) {
  std::string const prefix = "Content-Length:";
  while (true) {
    auto state = JsonrpcState::INITIAL;
    auto contentLength = 0;
    auto breakFromLoop = false;
    std::string header;

    while (!breakFromLoop) {
      auto chr = this->input.get();
      if (chr == EOF) {
        return;
      }
      switch (chr) {
        using enum JsonrpcState;
      case '\r':
        state = state == JsonrpcState::FIRST_N ? SECOND_R : FIRST_R;
        break;
      case '\n':
        if (state == SECOND_R) {
          breakFromLoop = true;
          break;
        }
        state = FIRST_N;
        if (header.starts_with(prefix)) {
          auto numberAsStr = header.substr(prefix.length());
          contentLength = std::stoi(numberAsStr);
        }
        break;
      default:
        header += (char)chr;
        state = READING;
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
      this->returnError(nullptr, JsonrpcError::PARSE_ERROR,
                        std::format("Invalid JSON: {}", ex.what()));
    }
  }
}

void jsonrpc::JsonRpcServer::exit() { this->shouldExit = true; }

jsonrpc::JsonRpcHandler::JsonRpcHandler() = default;

void jsonrpc::JsonRpcServer::wait() {
  for (auto &future : this->futures) {
    future.get();
  }
}
