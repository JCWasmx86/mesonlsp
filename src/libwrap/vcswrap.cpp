#include "ini.hpp"
#include "wrap.hpp"

VcsWrap::VcsWrap(ast::ini::Section *section) : Wrap(section) {
  if (auto url = section->findStringValue("url")) {
    this->url = url.value();
  }
  if (auto revision = section->findStringValue("revision")) {
    this->revision = revision.value();
  }
}
