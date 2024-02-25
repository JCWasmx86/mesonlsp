#include "shared.hpp"

#include "log.hpp"
#include "polyfill.hpp"

#include <cxxabi.h>
#include <dlfcn.h>
#include <typeinfo>

const static Logger LOG("cxathrow"); // NOLINT

void logExceptionType(const void *thrownException,
                      const std::type_info *typeinfo) {
  auto *demangled =
      abi::__cxa_demangle(typeinfo->name(), nullptr, nullptr, nullptr);
  LOG.debug(std::format("Exception of type {}",
                        demangled ? demangled : typeinfo->name()));
  if (demangled) {
    free(demangled);
  }
#ifndef __APPLE__
  const auto *exc =
      dynamic_cast<const abi::__class_type_info *>(&typeid(std::exception));
  const auto *cti = dynamic_cast<const abi::__class_type_info *>(typeinfo);

  if (cti && exc) {
    auto *casted = reinterpret_cast<std::exception *>(
        abi::__dynamic_cast(thrownException, exc, cti, -1));
    if (casted) {
      LOG.debug(std::format("  what(): {}", casted->what()));
    }
  }
#endif
}
