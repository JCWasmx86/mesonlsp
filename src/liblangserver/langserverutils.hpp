#pragma once

#include "lsptypes.hpp"
#include "mesonmetadata.hpp"
#include "node.hpp"

#include <ada.h>
#include <cassert>
#include <filesystem>
#include <string>

inline std::filesystem::path extractPathFromUrl(const std::string &urlStr) {
  auto url = ada::parse<ada::url>(urlStr);
  assert(url);
  assert(url->get_protocol() == "file:");
  auto input = url->get_pathname();
  auto ret = ada::unicode::percent_decode(input, input.find('%'));
  return {ret};
}

inline std::string pathToUrl(const std::filesystem::path &path) {
  return ada::href_from_file(path.generic_string());
}

inline LSPDiagnostic makeLSPDiagnostic(const Diagnostic &diag) {
  auto range = LSPRange(LSPPosition(diag.startLine, diag.startColumn),
                        LSPPosition(diag.endLine, diag.endColumn));
  auto severity = diag.severity == Severity::ERROR
                      ? DiagnosticSeverity::LSPError
                      : DiagnosticSeverity::LSPWarning;
  std::vector<DiagnosticTag> tags;
  if (diag.deprecated) {
    tags.push_back(DiagnosticTag::LSPDeprecated);
  }
  if (diag.unnecessary) {
    tags.push_back(DiagnosticTag::LSPUnnecessary);
  }
  return {range, severity, diag.message, tags};
}

inline LSPRange nodeToRange(const Node *node) {
  const auto &loc = node->location;
  return {LSPPosition(loc.startLine, loc.startColumn),
          LSPPosition(loc.endLine, loc.endColumn)};
}
