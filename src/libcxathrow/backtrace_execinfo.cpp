#include "log.hpp"
#include "polyfill.hpp"
#include "shared.hpp"

#include <cxxabi.h>
#include <dlfcn.h>
#include <execinfo.h>

constexpr auto BACKTRACE_LENGTH = 100;

void doBacktrace() {
  std::array<void *, BACKTRACE_LENGTH> backtraces;
  auto btSize = backtrace(backtraces.data(), BACKTRACE_LENGTH);
  for (auto i = 0; i < btSize; i++) {
    printAddr(i, backtraces[i]);
  }
}
