#include "jsonrpc.hpp"
#include <cassert>
#include <cstdio>
#include <nlohmann/json.hpp>

void jsonrpc::JsonRpcServer::evaluateData(
    std::shared_ptr<jsonrpc::JsonRpcHandler> handler, nlohmann::json data) {}
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
      if (ch == EOF)
        return;
      ;
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
    }
    std::string messageData;
    messageData.reserve(contentLength + 1);
    this->input.read(messageData.data(), contentLength);
    auto data = nlohmann::json::parse(messageData);
    this->evaluateData(handler, data);
  }
}