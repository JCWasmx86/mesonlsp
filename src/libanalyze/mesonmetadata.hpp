#pragma once

#include "function.hpp"
#include "node.hpp"

#include <cstdint>
#include <map>
#include <memory>
#include <string>
#include <tuple>
#include <utility>
#include <vector>

enum Severity {
  Warning,
  Error,
};

class Diagnostic {
public:
  Severity severity;
  uint32_t startLine;
  uint32_t endLine;
  uint32_t startColumn;
  uint32_t endColumn;
  std::string message;

  Diagnostic(Severity sev, Node *begin, Node *end, std::string message) {
    this->severity = sev;
    const auto *loc = begin->location;
    this->startLine = loc->startLine;
    this->startColumn = loc->startColumn;
    loc = end->location;
    this->endLine = loc->endLine;
    this->endColumn = loc->endColumn;
    this->message = std::move(message);
  }

  Diagnostic(Severity sev, Node *node, std::string message)
      : Diagnostic(sev, node, node, std::move(message)) {}
};

class MesonMetadata {
public:
  // Sadly raw pointers due to only getting raw pointers to the
  // code visitor.
  std::map<std::filesystem::path, std::vector<FunctionExpression *>>
      subdirCalls;
  std::map<std::filesystem::path, std::vector<MethodExpression *>> methodCalls;
  std::map<std::filesystem::path, std::vector<SubscriptExpression *>>
      arrayAccess;
  std::map<std::filesystem::path, std::vector<FunctionExpression *>>
      functionCalls;
  std::map<std::filesystem::path, std::vector<IdExpression *>> identifiers;
  std::map<std::filesystem::path, std::vector<StringLiteral *>> stringLiterals;
  std::map<std::filesystem::path,
           std::vector<std::tuple<KeywordItem *, std::shared_ptr<Function>>>>
      kwargs;
  std::map<std::filesystem::path, std::vector<Diagnostic>> diagnostics;

  void registerDiagnostic(Node *node, const Diagnostic &diag) {
    auto key = node->file->file;
    if (this->diagnostics.contains(key)) {
      this->diagnostics[key].push_back(diag);
    } else {
      this->diagnostics[key] = {diag};
    }
  }

  void clear() {
    this->subdirCalls = {};
    this->methodCalls = {};
    this->arrayAccess = {};
    this->functionCalls = {};
    this->identifiers = {};
    this->stringLiterals = {};
    this->kwargs = {};
    this->diagnostics = {};
  }
};
