#include "log.hpp"
#include "polyfill.hpp"
#include "shared.hpp"

#include <array>
#include <cstdint>
#include <cxxabi.h>
#include <dlfcn.h>
#include <execinfo.h>

constexpr auto BACKTRACE_LENGTH = 100;
const static Logger LOG("cxathrow"); // NOLINT
static void printAddr(uint32_t idx, void *addr);

void doBacktrace() {
  std::array<void *, BACKTRACE_LENGTH> backtraces;
  auto btSize = backtrace(backtraces.data(), BACKTRACE_LENGTH);
  for (auto i = 0; i < btSize; i++) {
    printAddr(i, backtraces[i]);
  }
}

static void printAddr(uint32_t idx, void *addr) {
  Dl_info info;
  if (dladdr(addr, &info) != 0) {
    if (info.dli_sname == nullptr) {
      info.dli_sname = "???";
    }
    if (info.dli_saddr == nullptr) {
      info.dli_saddr = addr;
    }
    auto *demangled =
        abi::__cxa_demangle(info.dli_sname, nullptr, nullptr, nullptr);
    auto offset = (unsigned char *)addr - (unsigned char *)info.dli_saddr;
    const auto *symName = demangled ? demangled : info.dli_sname;
    LOG.debug(std::format("#{}: {}({}+{:#x}) [{}]", idx, info.dli_fname,
                          symName, offset, addr));
    if (demangled) {
      free(demangled);
    }
  } else {
    LOG.debug(std::format("#{}: {}", idx, addr));
  }
}
