#include "shared.hpp"

#include "log.hpp"
#include "polyfill.hpp"

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
