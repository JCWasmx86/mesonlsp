#include "ini.hpp"
#include "wrap.hpp"
#include <charconv>

GitWrap::GitWrap(ast::ini::Section *section) : VcsWrap(section) {
  if (auto pushUrl = section->find_string_value("push-url")) {
    this->pushUrl = pushUrl;
  }
  if (auto depthString = section->find_string_value("depth")) {
    int number;
    auto res = std::from_chars(
        depthString->data(), depthString->data() + depthString->size(), number);
    if (res.ec == std::errc{})
      this->depth = number;
  }
  if (auto val = section->find_string_value("clone-recursive")) {
    this->cloneRecursive = val == "true";
  }
}
