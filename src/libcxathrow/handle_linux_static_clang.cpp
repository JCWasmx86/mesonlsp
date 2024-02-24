#include "shared.hpp"

#include <cxxabi.h>

void /*NOLINT*/ __real___cxa_throw(void *, std::type_info *, void (*)(void *));

void
    __wrap___cxa_throw /*NOLINT*/ (void *thrown_exception,
                                   std::type_info *typeinfo,
                                   void(_GLIBCXX_CDTOR_CALLABI *dest)(void *)) {
  logExceptionType(typeinfo);
  __real___cxa_throw(thrown_exception, typeinfo, dest);
}
