#include "ini.hpp"
#include "wrap.hpp"

VcsWrap::VcsWrap(ast::ini::Section *section) : Wrap(section) {
  if (auto optUrl = section->findStringValue("url")) {
    this->url = optUrl.value();
  }
  if (auto optRevision = section->findStringValue("revision")) {
    this->revision = optRevision.value();
  }
}
