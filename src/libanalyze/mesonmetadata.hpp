#pragma once

#include "function.hpp"
#include "node.hpp"

#include <cstdint>
#include <filesystem>
#include <format>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <string>
#include <tuple>
#include <utility>
#include <vector>

enum Severity {
  Warning,
  Error,
};

#define REGISTER(methodName, variable, type)                                   \
  void methodName(type *node) {                                                \
    auto key = node->file->file;                                               \
    if (this->variable.contains(key)) {                                        \
      this->variable[key].push_back(node);                                     \
    } else {                                                                   \
      this->variable[key] = {node};                                            \
    }                                                                          \
  }

#define FIND(type, variable)                                                   \
  std::optional<type *> find##type##At(const std::filesystem::path &path,      \
                                       uint64_t line, uint64_t column) {       \
    if (!this->variable.contains(path)) {                                      \
      return std::nullopt;                                                     \
    }                                                                          \
    for (auto &var : this->variable[path]) {                                   \
      if (MesonMetadata::contains(var->id.get(), line, column)) {              \
        return var;                                                            \
      }                                                                        \
    }                                                                          \
    return std::nullopt;                                                       \
  }

#define FIND_FULL(type, variable)                                              \
  std::optional<type *> find##type##At(const std::filesystem::path &path,      \
                                       uint64_t line, uint64_t column) {       \
    if (!this->variable.contains(path)) {                                      \
      return std::nullopt;                                                     \
    }                                                                          \
    for (auto &var : this->variable[path]) {                                   \
      if (MesonMetadata::contains(var, line, column)) {                        \
        return var;                                                            \
      }                                                                        \
    }                                                                          \
    return std::nullopt;                                                       \
  }

class Diagnostic {
public:
  Severity severity;
  uint32_t startLine;
  uint32_t endLine;
  uint32_t startColumn;
  uint32_t endColumn;
  std::string message;

  Diagnostic(Severity sev, const Node *begin, const Node *end,
             std::string message) {
    this->severity = sev;
    const auto *loc = begin->location;
    this->startLine = loc->startLine;
    this->startColumn = loc->startColumn;
    loc = end->location;
    this->endLine = loc->endLine;
    this->endColumn = loc->endColumn;
    this->message = std::move(message);
  }

  Diagnostic(Severity sev, const Node *node, std::string message)
      : Diagnostic(sev, node, node, std::move(message)) {}
};

class MesonMetadata {
public:
  // Sadly raw pointers due to only getting raw pointers to the
  // code visitor.
  std::map<std::filesystem::path, std::set<std::string>> subdirCalls;
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
  std::vector<IdExpression *> encounteredIds;

  void registerDiagnostic(const Node *node, const Diagnostic &diag) {
    auto key = node->file->file;
    if (this->diagnostics.contains(key)) {
      this->diagnostics[key].push_back(diag);
    } else {
      this->diagnostics[key] = {diag};
    }
  }

  void registerSubdirCall(FunctionExpression *node,
                          const std::set<std::string> &subdirs) {
    auto key = std::format("{}-{}", node->file->file.generic_string(),
                           node->location->format());
    this->subdirCalls[key] = subdirs;
  }
  REGISTER(registerArrayAccess, arrayAccess, SubscriptExpression)
  REGISTER(registerStringLiteral, stringLiterals, StringLiteral)
  REGISTER(registerMethodCall, methodCalls, MethodExpression)
  REGISTER(registerFunctionCall, functionCalls, FunctionExpression)

  void registerIdentifier(IdExpression *node) {
    auto key = node->file->file;
    if (this->identifiers.contains(key)) {
      this->identifiers[key].push_back(node);
    } else {
      this->identifiers[key] = {node};
    }
    this->encounteredIds.push_back(node);
  }

  void registerKwarg(KeywordItem *item, std::shared_ptr<Function> func) {
    auto key = item->file->file;
    if (this->kwargs.contains(key)) {
      this->kwargs[key].emplace_back(item, func);
    } else {
      this->kwargs[key] = {std::make_tuple(item, func)};
    }
  }

  FIND(MethodExpression, methodCalls)
  FIND(FunctionExpression, functionCalls)
  FIND_FULL(IdExpression, identifiers)

  void clear() {
    this->subdirCalls = {};
    this->methodCalls = {};
    this->arrayAccess = {};
    this->functionCalls = {};
    this->identifiers = {};
    this->stringLiterals = {};
    this->kwargs = {};
    this->diagnostics = {};
    this->encounteredIds = {};
  }

  static inline bool contains(const Node *node, uint64_t line,
                              uint64_t column) {
    const auto *loc = node->location;
    if (loc->startLine > line || node->location->endLine < line) {
      return false;
    }
    if (loc->startLine == node->location->endLine) {
      return loc->startColumn <= column && loc->endColumn >= column;
    }
    if (loc->startLine < line && loc->endLine > line) {
      return true;
    }
    if (loc->startLine == line && loc->startColumn <= column) {
      return true;
    }
    if (loc->endLine == line && loc->endColumn >= column) {
      return true;
    }
    return false;
  }
};

#undef REGISTER
