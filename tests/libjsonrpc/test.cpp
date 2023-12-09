#include <cstring>
#include <format>
#include <jsonrpc.hpp>
#include <log.hpp>
#include <memory>
#include <nlohmann/json.hpp>
#include <sstream>
#include <string>

class TestJsonRpcHandler : public jsonrpc::JsonRpcHandler {
private:
  Logger logger;

public:
  TestJsonRpcHandler() : logger(Logger("TestJsonRpcHandler")) {}
  void handleNotification(std::string method, nlohmann::json params) override {
    this->logger.info(std::format("Got notification: {}", method));
  }

  void handleRequest(std::string method, nlohmann::json callId,
                     nlohmann::json params) override {
    this->logger.info(std::format("Got request: {}", method));
    if (strcmp(method.data(), "add") == 0) {
      int a = params["a"];
      int b = params["b"];
      nlohmann::json data;
      data["c"] = a + b;
      this->server->reply(callId, data);
    }
  }

  ~TestJsonRpcHandler() = default;
};

static std::string make_json_rpc_call(int id, std::string method,
                                      nlohmann::json params) {
  nlohmann::json data;
  data["jsonrpc"] = "2.0";
  data["method"] = method;
  data["params"] = params;
  data["id"] = id;
  std::string payload = data.dump();
  auto len = payload.size();
  return std::format("Content-Length:{}\r\n\r\n{}", len, payload);
}

static std::string make_json_rpc_notification(std::string method,
                                              nlohmann::json params) {
  nlohmann::json data;
  data["jsonrpc"] = "2.0";
  data["method"] = method;
  data["params"] = params;
  std::string payload = data.dump();
  auto len = payload.size();
  return std::format("Content-Length:{}\r\n\r\n{}", len, payload);
}

static std::string make_input_msg() {
  std::string ret;
  ret += make_json_rpc_call(1, "add", R"({"a": 3, "b": 2})"_json);
  ret += make_json_rpc_notification("notif", R"({"msg": "Foo"})"_json);
  return ret;
}

int main(int argc, char **argv) {
  auto handler = std::make_shared<TestJsonRpcHandler>();
  std::istringstream new_sin(make_input_msg());
  std::ostringstream new_sout;
  auto server = std::make_shared<jsonrpc::JsonRpcServer>(new_sin, new_sout);
  handler->server = server;
  server->loop(handler);
  server->wait();
  std::cout << new_sout.str() << std::endl;
}
