#include <log.hpp>

int main(int /*unused*/, char ** /*unused*/) {
  Logger log("my-module");
  log.error("I'm an error");
  log.info("I'm info");
  log.warn("I'm a warning");
}
