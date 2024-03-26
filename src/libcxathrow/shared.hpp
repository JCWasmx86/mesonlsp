#pragma once

#include <typeinfo>
#if defined(__linux__) || defined(_WIN32)
#ifdef __GNUC__
using CxaThrowType = void
    __attribute__((__noreturn__)) (*)(void *, void *, void (*)(void *));
#elif defined(__clang__)
using CxaThrowType = void
    __attribute__((__noreturn__)) (*)(void *, std::type_info *,
                                      void(_GLIBCXX_CDTOR_CALLABI *)(void *));
#endif
#elif defined(__APPLE__)
using CxaThrowType = void (*)(void *, std::type_info *, void (*)(void *));
#endif

void logExceptionType(const void *thrownException,
                      const std::type_info *typeinfo);
void doBacktrace();
