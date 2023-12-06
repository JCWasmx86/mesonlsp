#pragma once

#include <fstream>
#include <iostream>
#include <istream>
#include <memory>
#include <nlohmann/json.hpp>
#include <ostream>
#include <sstream>

namespace jsonrpc {

class JsonRpcHandler;

class JsonRpcServer {
private:
  std::istream &input;
  std::ostream &output;
  void evaluateData(std::shared_ptr<jsonrpc::JsonRpcHandler> handler,
                    nlohmann::json data);

public:
  JsonRpcServer() : input(std::cin), output(std::cout) {}

  JsonRpcServer(std::istringstream &input, std::ostringstream &output)
      : input(input), output(output) {}
  void loop(std::shared_ptr<JsonRpcHandler> handler);
  void reply(nlohmann::json callId, nlohmann::json result);
  void notification(std::string method, nlohmann::json params);
  void exit();
};

class JsonRpcHandler {
public:
  JsonRpcHandler();
  virtual ~JsonRpcHandler();
  void handleNotification(std::string method, nlohmann::json params);
  void handleRequest(std::string method, nlohmann::json callId,
                     nlohmann::json params);
};
}; // namespace jsonrpc