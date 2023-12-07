#pragma once

#include <fstream>
#include <future>
#include <iostream>
#include <istream>
#include <memory>
#include <mutex>
#include <nlohmann/json.hpp>
#include <ostream>
#include <sstream>
#include <vector>

namespace jsonrpc {

enum JsonrpcError {
  ParseError,
  InvalidRequest,
  MethodNotFound,
  InvalidParams,
  InternalError,
};

class JsonRpcHandler;

class JsonRpcServer {
private:
  std::istream &input;
  std::ostream &output;
  std::mutex output_mutex;
  std::vector<std::future<void>> futures;
  void evaluateData(std::shared_ptr<jsonrpc::JsonRpcHandler> handler,
                    nlohmann::json data);
  void sendToClient(nlohmann::json data);
  bool shouldExit;

public:
  JsonRpcServer() : input(std::cin), output(std::cout), shouldExit(false) {}
  JsonRpcServer(std::istringstream &input, std::ostringstream &output)
      : input(input), output(output), shouldExit(false) {}
  void loop(std::shared_ptr<JsonRpcHandler> handler);
  void reply(nlohmann::json callId, nlohmann::json result);
  void notification(std::string method, nlohmann::json params);
  void returnError(JsonrpcError error, std::string message);
  void exit();
  void wait();
};

class JsonRpcHandler {
public:
  std::shared_ptr<JsonRpcServer> server = nullptr;
  JsonRpcHandler();
  virtual ~JsonRpcHandler() {}
  virtual void handleNotification(std::string method,
                                  nlohmann::json params) = 0;
  virtual void handleRequest(std::string method, nlohmann::json callId,
                             nlohmann::json params) = 0;
};
}; // namespace jsonrpc