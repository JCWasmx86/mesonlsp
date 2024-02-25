#include "log.hpp"
#include "polyfill.hpp"
#include "shared.hpp"

#include <cstdlib>
#include <cxxabi.h>
#include <dlfcn.h>
#include <execinfo.h>
#include <format>

const static Logger LOG("cxathrow"); // NOLINT
constexpr auto BACKTRACE_LENGTH = 100;

void doBacktrace() {
  void *backtraces[BACKTRACE_LENGTH];
  auto btSize = backtrace(backtraces, BACKTRACE_LENGTH);
  for (auto i = 0; i < btSize; i++) {
    Dl_info info;
    if (dladdr(backtraces[i], &info) != 0) {
      if (info.dli_sname == nullptr) {
        info.dli_sname = "???";
      }
      if (info.dli_saddr == nullptr) {
        info.dli_saddr = backtraces[i];
      }
      auto *demangled =
          abi::__cxa_demangle(info.dli_sname, nullptr, nullptr, nullptr);
      auto offset =
          (unsigned char *)backtraces[i] - (unsigned char *)info.dli_saddr;
      const auto *symName = demangled ? demangled : info.dli_sname;
      LOG.debug(std::format("#{}: {}({}+{:#x}) [{}]", i, info.dli_fname,
                            symName, offset, backtraces[i]));
      if (demangled) {
        free(demangled);
      }
    } else {
      LOG.debug(std::format("#{}: {}", i, backtraces[i]));
    }
  }
}
