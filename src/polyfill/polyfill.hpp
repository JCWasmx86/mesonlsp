#pragma once

#if defined(__APPLE__)
#if __has_include(<format>) and !defined(__x86_64__)
#include <format>
#else
#include <chrono>
#include <fmt/core.h>

namespace std {
using fmt::format;
}

template <typename Clock, typename Duration>
struct fmt::formatter<std::chrono::time_point<Clock, Duration>> {
  // Presentation format: 'f' for full format
  constexpr auto parse(format_parse_context &ctx) { return ctx.begin(); }

  // Format the time point
  template <typename FormatContext>
  auto format(const std::chrono::time_point<Clock, Duration> &tp,
              FormatContext &ctx) {
    return fmt::format_to(ctx.out(), "{}", tp.time_since_epoch().count());
  }
};
#endif
#else
#include <format>
#ifdef _WIN32
template <> struct std::formatter<wchar_t *> {
  constexpr auto parse(format_parse_context &ctx) { return ctx.begin(); }

  template <typename FormatContext>
  auto format(const wchar_t *str, FormatContext &ctx) {
    return std::format_to(ctx.out(), L"{}", str);
  }
};

#endif
#endif
