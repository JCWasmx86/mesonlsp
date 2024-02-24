#include "log.hpp"
#include "polyfill.hpp"
#include "shared.hpp"

#include <execinfo.h>

const static Logger LOG("cxathrow"); // NOLINT
constexpr auto BACKTRACE_LENGTH = 100;

void doBacktrace() {
  void *backtraces[BACKTRACE_LENGTH];
  auto btSize = backtrace(backtraces, BACKTRACE_LENGTH);
  auto *btSyms = backtrace_symbols(backtraces, btSize);
  for (auto i = 0; i < btSize; i++) {
    LOG.debug(std::format("#{}: {}", i, btSyms[i]));
  }
  free(btSyms);
}
