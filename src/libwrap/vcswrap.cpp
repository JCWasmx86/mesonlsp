#include "ini.hpp"
#include "wrap.hpp"

VcsWrap::VcsWrap(ast::ini::Section *section) : Wrap(section) {
  if (auto url = section->find_string_value("url")) {
    this->url = url.value();
  }
  if (auto revision = section->find_string_value("revision")) {
    this->revision = revision.value();
  }
}
