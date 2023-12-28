#pragma once

#include "lsptypes.hpp"
#include "mesonmetadata.hpp"

#include <ada.h>
#include <cassert>
#include <filesystem>
#include <string>

inline std::filesystem::path extractPathFromUrl(const std::string &urlStr) {
  auto url = ada::parse<ada::url>(urlStr);
  assert(url);
  assert(url->get_protocol() == "file:");
  return {url->path};
}

inline std::string pathToUrl(const std::filesystem::path &path) {
  return ada::href_from_file(path.generic_string());
}

inline LSPDiagnostic makeLSPDiagnostic(const Diagnostic &diag) {
  auto range = LSPRange(LSPPosition(diag.startLine, diag.startColumn),
                        LSPPosition(diag.endLine, diag.endColumn));
  auto severity = diag.severity == Severity::Error
                      ? DiagnosticSeverity::LSPError
                      : DiagnosticSeverity::LSPWarning;
  return {range, severity, diag.message};
}
