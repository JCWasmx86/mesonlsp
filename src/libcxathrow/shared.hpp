#pragma once

#include <cstdint>
#include <typeinfo>
#ifdef __linux__
#ifdef __GNUC__
typedef /*NOLINT*/ void
    __attribute__((__noreturn__)) (*CxaThrowType)(void *, void *,
                                                  void (*)(void *));
#elif defined(__clang__)
typedef void __attribute__((__noreturn__)) /*NOLINT*/ (*CxaThrowType)(
    void *, std::type_info *, void(_GLIBCXX_CDTOR_CALLABI *)(void *));
#endif
#endif

void logExceptionType(const std::type_info *typeinfo);
void doBacktrace();
void printAddr(uint32_t idx, void *addr);
