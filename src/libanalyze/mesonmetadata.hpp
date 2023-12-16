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

  Diagnostic(Severity sev, Node *node, std::string message) {
    this->severity = sev;
    const auto *loc = node->location;
    this->startLine = loc->startLine;
    this->endLine = loc->endLine;
    this->startColumn = loc->startColumn;
    this->endColumn = loc->endColumn;
    this->message = std::move(message);
  }
};

class MesonMetadata {
public:
  // Sadly raw pointers due to only getting raw pointers to the
  // code visitor.
  std::map<std::string, std::vector<FunctionExpression *>> subdirCalls;
  std::map<std::string, std::vector<MethodExpression *>> methodCalls;
  std::map<std::string, std::vector<SubscriptExpression *>> arrayAccess;
  std::map<std::string, std::vector<FunctionExpression *>> functionCalls;
  std::map<std::string, std::vector<IdExpression *>> identifiers;
  std::map<std::string, std::vector<StringLiteral *>> stringLiterals;
  std::map<std::string,
           std::vector<std::tuple<KeywordItem *, std::shared_ptr<Function>>>>
      kwargs;
  std::map<std::string, std::vector<Diagnostic>> diagnostics;
};
