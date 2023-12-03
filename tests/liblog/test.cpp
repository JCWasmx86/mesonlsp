#include <log.cpp>

int
main(int argc, char** argv)
{
  Logger log("my-module");
  log.error("I'm an error");
  log.info("I'm info");
  log.warn("I'm a warning");
}