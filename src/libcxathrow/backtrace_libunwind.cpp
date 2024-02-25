#include <cstdint>
#include <libunwind-x86_64.h>
#define UNW_LOCAL_ONLY
#include "polyfill.hpp"
#include "shared.hpp"

#include <cxxabi.h>
#include <dlfcn.h>
#include <execinfo.h>
#include <libunwind.h>

void doBacktrace() {
  unw_cursor_t cursor;
  unw_context_t context;

  // Initialize cursor to current frame
  unw_getcontext(&context);
  unw_init_local(&cursor, &context);
  uint32_t idx = 0;
  while (unw_step(&cursor) > 0) {
    unw_word_t /*NOLINT*/ pc;
    unw_get_reg(&cursor, UNW_REG_IP, &pc);
    printAddr(idx, (void *)pc);
    idx++;
  }
}
