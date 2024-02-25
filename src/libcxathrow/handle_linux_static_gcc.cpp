#include "shared.hpp"

#include <cxxabi.h>

extern "C" void /*NOLINT*/ __real___cxa_throw(void *, void *, void (*)(void *));

extern "C" void __wrap___cxa_throw /*NOLINT*/
    (void * /*NOLINT*/ thrown_exception, void *pvtinfo, void (*dest)(void *)) {
  const auto *typeinfo = (const std::type_info *)pvtinfo;
  logExceptionType(thrown_exception, typeinfo);
  doBacktrace();
  __real___cxa_throw(thrown_exception, pvtinfo, dest);
}
