#pragma once

#if defined(__APPLE__)
#include <chrono>
#include <fmt/core.h>

#ifdef __x86_64__
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
#elif defined(_WIN32)
#include <codecvt>
#include <format>
#include <locale>

template <> struct std::formatter<wchar_t *> {
  constexpr auto parse(format_parse_context &ctx) { return ctx.begin(); }

  template <typename FormatContext>
  auto format(const wchar_t *str, FormatContext &ctx) {
    return std::format_to(ctx.out(), L"{}", str);
  }
};

template <>
struct std::formatter<const wchar_t *, char>
    : std::formatter<std::string, char> {
  template <typename FormatContext>
  auto format(const wchar_t *value, FormatContext &ctx) const {
    std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;
    return std::formatter<std::string, char>::format(converter.to_bytes(value),
                                                     ctx);
  }
};

#else
#include <format>
#endif
