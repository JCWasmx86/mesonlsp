#include "log.hpp"
#include "polyfill.hpp"
#include "shared.hpp"

#include <cxxabi.h>
#include <stacktrace>

const static Logger LOG("cxathrow"); // NOLINT

void doBacktrace() {
  auto stacktrace = std::stacktrace::current();
  auto idx = 0;
  for (const auto &element : stacktrace) {
    LOG.debug(std::format("#{}: {} ({}:{})", idx, element.description(),
                          element.source_file(), element.source_line()));
    idx++;
  }
}
