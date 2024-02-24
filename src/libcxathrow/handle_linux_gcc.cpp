#include "shared.hpp"

#include <dlfcn.h>

CxaThrowType origCxaThrow = nullptr;

void __cxa_throw /*NOLINT*/ (void *thrown_exception, void *pvtinfo,
                             void (*dest)(void *)) {
  if (origCxaThrow == nullptr) {
    origCxaThrow = (CxaThrowType)dlsym(RTLD_NEXT, "__cxa_throw");
  }
  const auto *typeinfo = (const std::type_info *)pvtinfo;
  logExceptionType(typeinfo);
  origCxaThrow(thrown_exception, pvtinfo, dest);
}