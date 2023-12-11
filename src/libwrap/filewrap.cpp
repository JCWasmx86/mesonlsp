#include "ini.hpp"
#include "wrap.hpp"

FileWrap::FileWrap(ast::ini::Section *section) : Wrap(section) {
  if (auto val = section->find_string_value("source_url")) {
    this->sourceUrl = val.value();
  }
  if (auto val = section->find_string_value("source_fallback_url")) {
    this->sourceFallbackUrl = val.value();
  }
  if (auto val = section->find_string_value("source_filename")) {
    this->sourceFilename = val.value();
  }
  if (auto val = section->find_string_value("source_hash")) {
    this->sourceHash = val.value();
  }
  if (auto val = section->find_string_value("lead_directory_missing")) {
    this->leadDirectoryMissing = val == "true";
  }
}
