#include "shared.hpp"

#include "log.hpp"
#include "polyfill.hpp"

#include <cstdint>
#include <cxxabi.h>
#include <dlfcn.h>
#include <typeinfo>

const static Logger LOG("cxathrow"); // NOLINT

void logExceptionType(const std::type_info *typeinfo) {
  auto *demangled =
      abi::__cxa_demangle(typeinfo->name(), nullptr, nullptr, nullptr);
  LOG.debug(std::format("Exception of type {}",
                        demangled ? demangled : typeinfo->name()));
  if (demangled) {
    free(demangled);
  }
}

void printAddr(uint32_t idx, void *addr) {
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
