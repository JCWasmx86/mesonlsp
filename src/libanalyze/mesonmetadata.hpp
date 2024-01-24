#pragma once

#include "function.hpp"
#include "node.hpp"

#include <cassert>
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

enum class Severity {
  WARNING,
  ERROR,
};

#define REGISTER(methodName, variable, type)                                   \
  void methodName(type *node) /*NOLINT*/ {                                     \
    const auto &key = node->file->file;                                        \
    if (this->variable.contains(key)) {                                        \
      this->variable[key].push_back(node);                                     \
    } else {                                                                   \
      this->variable[key] = {node};                                            \
    }                                                                          \
  }

#define FIND(type, variable)                                                   \
  std::optional<type *> /*NOLINT*/ find##type##At(                             \
      const std::filesystem::path &path, uint64_t line, uint64_t column) {     \
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
  std::optional<type *> /*NOLINT*/ find##type##At(                             \
      const std::filesystem::path &path, uint64_t line, uint64_t column)       \
      const {                                                                  \
    if (!this->variable.contains(path)) {                                      \
      return std::nullopt;                                                     \
    }                                                                          \
    for (auto &var : this->variable.at(path)) {                                \
      if (MesonMetadata::contains(var, line, column)) {                        \
        return var;                                                            \
      }                                                                        \
    }                                                                          \
    return std::nullopt;                                                       \
  }

#define FIND_FULL2(type, variable)                                             \
  std::optional<type *> /*NOLINT*/ findFull##type##At(                         \
      const std::filesystem::path &path, uint64_t line, uint64_t column)       \
      const {                                                                  \
    if (!this->variable.contains(path)) {                                      \
      return std::nullopt;                                                     \
    }                                                                          \
    for (auto &var : this->variable.at(path)) {                                \
      if (MesonMetadata::contains(var, line, column)) {                        \
        return var;                                                            \
      }                                                                        \
    }                                                                          \
    return std::nullopt;                                                       \
  }

class Diagnostic {
public:
  std::string message;
  Severity severity;
  uint32_t startLine;
  uint32_t endLine;
  uint32_t startColumn;
  uint32_t endColumn;
  bool deprecated;
  bool unnecessary;

  Diagnostic(Severity sev, const Node *begin, const Node *end,
             std::string message, bool deprecated = false,
             bool unnecessary = false)
      : message(std::move(message)), severity(sev), deprecated(deprecated),
        unnecessary(unnecessary) {
    assert(begin);
    assert(end);
    const auto *loc = &begin->location;
    this->startLine = loc->startLine;
    this->startColumn = loc->startColumn;
    loc = &end->location;
    this->endLine = loc->endLine;
    this->endColumn = loc->endColumn;
  }

  Diagnostic(Severity sev, const Node *node, std::string message)
      : Diagnostic(sev, node, node, std::move(message)) {}

  Diagnostic(Severity sev, const Node *node, std::string message,
             bool deprecated, bool unnecessary)
      : Diagnostic(sev, node, node, std::move(message), deprecated,
                   unnecessary) {}
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
  std::map<std::string, std::tuple<std::filesystem::path, uint32_t, uint32_t>>
      options;
  std::vector<std::vector<IdExpression *>> idExprs;
  std::vector<std::vector<StringLiteral *>> tempStringLiterals;
  std::vector<std::vector<std::tuple<KeywordItem *, std::shared_ptr<Function>>>>
      tempKwargs;
  std::vector<std::vector<FunctionExpression *>> tempFuncCalls;
  std::vector<std::vector<MethodExpression *>> tempMethodCalls;

  MesonMetadata() { this->encounteredIds.reserve(1024); }

  void registerDiagnostic(const Node *node, const Diagnostic &diag) {
    const auto &key = node->file->file;
    if (this->diagnostics.contains(key)) {
      this->diagnostics[key].push_back(diag);
    } else {
      this->diagnostics[key] = {diag};
    }
  }

  void registerSubdirCall(FunctionExpression *node,
                          const std::set<std::string> &subdirs) {
    const auto &key = std::format("{}-{}", node->file->file.generic_string(),
                                  node->location.format());
    this->subdirCalls[key] = subdirs;
  }

  void registerOption(const StringLiteral *literal) {
    this->options[literal->id] =
        std::make_tuple(literal->file->file, literal->location.startLine,
                        literal->location.startColumn);
  }

  void registerStringLiteral(StringLiteral *node) {
    this->tempStringLiterals.back().push_back(node);
  }

  REGISTER(registerArrayAccess, arrayAccess, SubscriptExpression)

  void beginFile() {
    this->idExprs.emplace_back();
    this->tempStringLiterals.emplace_back();
    this->tempKwargs.emplace_back();
    this->tempFuncCalls.emplace_back();
    this->tempMethodCalls.emplace_back();
  }

  void registerFunctionCall(FunctionExpression *node) {
    this->tempFuncCalls.back().push_back(node);
  }

  void registerMethodCall(MethodExpression *node) {
    this->tempMethodCalls.back().push_back(node);
  }

  void registerIdentifier(IdExpression *node) {
    this->idExprs.back().push_back(node);
    this->encounteredIds.push_back(node);
  }

  void endFile(const std::filesystem::path &path) {
    this->identifiers[path] = this->idExprs.back();
    this->idExprs.pop_back();
    this->stringLiterals[path] = this->tempStringLiterals.back();
    this->tempStringLiterals.pop_back();
    this->kwargs[path] = this->tempKwargs.back();
    this->tempKwargs.pop_back();
    this->functionCalls[path] = this->tempFuncCalls.back();
    this->tempFuncCalls.pop_back();
    this->methodCalls[path] = this->tempMethodCalls.back();
    this->tempMethodCalls.pop_back();
  }

  void registerKwarg(KeywordItem *item, const std::shared_ptr<Function> &func) {
    this->tempKwargs.back().emplace_back(item, func);
  }

  FIND(MethodExpression, methodCalls)
  FIND(FunctionExpression, functionCalls)
  FIND_FULL(IdExpression, identifiers)
  FIND_FULL(SubscriptExpression, arrayAccess)
  FIND_FULL(StringLiteral, stringLiterals)

  FIND_FULL2(MethodExpression, methodCalls)
  FIND_FULL2(FunctionExpression, functionCalls)

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
    const auto *loc = &node->location;
    if (loc->startLine > line || loc->endLine < line) {
      return false;
    }
    if (loc->startLine == loc->endLine) {
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
