#pragma once

#include <future>
#include <iostream>
#include <istream>
#include <memory>
#include <mutex>
#include <nlohmann/json.hpp>
#include <ostream>
#include <sstream>
#include <string>
#include <vector>

namespace jsonrpc {

enum class JsonrpcError {
  PARSE_ERROR = -32700,
  INVALID_REQUEST = -32600,
  METHOD_NOT_FOUND = -32601,
  INVALID_PARAMS = -32602,
  INTERNAL_ERROR = -32603,
};

class JsonRpcHandler;

class JsonRpcServer {
private:
  std::istream &input;
  std::ostream &output;
  std::mutex output_mutex;
  std::vector<std::future<void>> futures;
  void evaluateData(const std::shared_ptr<jsonrpc::JsonRpcHandler> &handler,
                    nlohmann::json data);
  void sendToClient(const nlohmann::json &data);
  bool shouldExit = false;

public:
  JsonRpcServer() : input(std::cin), output(std::cout) {}

  JsonRpcServer(std::istringstream &input, std::ostringstream &output)
      : input(input), output(output) {}

  void loop(const std::shared_ptr<JsonRpcHandler> &handler);
  void reply(nlohmann::json callId, nlohmann::json result);
  void notification(const std::string &method, nlohmann::json params);
  void returnError(nlohmann::json callId, JsonrpcError error,
                   const std::string &message);
  void exit();
  void wait();
};

class JsonRpcHandler {
public:
  std::shared_ptr<JsonRpcServer> server = nullptr;
  JsonRpcHandler();

  virtual ~JsonRpcHandler() = default;

  virtual void handleNotification(std::string method,
                                  nlohmann::json params) = 0;
  virtual void handleRequest(std::string method, nlohmann::json callId,
                             nlohmann::json params) = 0;
};
}; // namespace jsonrpc
