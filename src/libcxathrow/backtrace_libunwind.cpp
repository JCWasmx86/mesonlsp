#include <cstdlib>
#include <format>
#define UNW_LOCAL_ONLY
#include "log.hpp"
#include "polyfill.hpp"
#include "shared.hpp"

#include <cstdint>
#include <cxxabi.h>
#include <libunwind.h>

constexpr auto SYMBOL_LENGTH = 2048;
const static Logger LOG("cxathrow"); // NOLINT

void doBacktrace() {
  unw_cursor_t cursor;
  unw_context_t context;

  // Initialize cursor to current frame
  unw_getcontext(&context);
  unw_init_local(&cursor, &context);
  uint32_t idx = 0;
  while (unw_step(&cursor) > 0) {
    unw_word_t /*NOLINT*/ pc;
    unw_word_t offset;
    unw_get_reg(&cursor, UNW_REG_IP, &pc);
    std::array<char, SYMBOL_LENGTH> symbolName;
    if (!unw_get_proc_name(&cursor, symbolName.data(), symbolName.size(),
                           &offset)) {
      auto *demangled =
          abi::__cxa_demangle(symbolName.data(), nullptr, nullptr, nullptr);
      const auto *symName = demangled ? demangled : symbolName.data();
      LOG.debug(
          std::format("#{}: {}+{:#x} [{}]", idx, symName, offset, (void *)pc));
      if (demangled) {
        free(demangled);
      }
    } else {
      LOG.debug(std::format("#{}: {}", idx, (void *)pc));
    }
    idx++;
  }
}
