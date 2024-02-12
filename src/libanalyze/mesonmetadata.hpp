#pragma once

#include "function.hpp"
#include "location.hpp"
#include "node.hpp"

#include <cassert>
#include <cstdint>
#include <filesystem>
#include <format>
#include <map>
#include <memory>
#include <optional>
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
    if (!this->fileMetadata.contains(path)) {                                  \
      return std::nullopt;                                                     \
    }                                                                          \
    for (auto &var : this->fileMetadata[path].variable) {                      \
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
    if (!this->fileMetadata.contains(path)) {                                  \
      return std::nullopt;                                                     \
    }                                                                          \
    for (auto &var : this->fileMetadata.at(path).variable) {                   \
      if (MesonMetadata::contains(var, line, column)) {                        \
        return var;                                                            \
      }                                                                        \
    }                                                                          \
    return std::nullopt;                                                       \
  }

#define FIND_FULL3(type, variable)                                             \
  std::optional<type *> /*NOLINT*/ find##type##At(                             \
      const std::filesystem::path &path, uint64_t line, uint64_t column)       \
      const {                                                                  \
    if (!this->fileMetadata.contains(path)) {                                  \
      return std::nullopt;                                                     \
    }                                                                          \
    for (auto &var : this->fileMetadata.at(path).variable) {                   \
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
  bool deprecated = false;
  bool unnecessary = false;

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

  Diagnostic(Severity sev, std::string message, const Location &location)
      : message(std::move(message)), severity(sev),
        startLine(location.startLine), endLine(location.endLine),
        startColumn(location.startColumn), endColumn(location.endColumn) {}

  Diagnostic(Severity sev, const Node *node, std::string message)
      : Diagnostic(sev, node, node, std::move(message)) {}

  Diagnostic(Severity sev, const Node *node, std::string message,
             bool deprecated, bool unnecessary)
      : Diagnostic(sev, node, node, std::move(message), deprecated,
                   unnecessary) {}
};

struct FileMetadata {
  std::vector<IdExpression *> identifiers;
  std::vector<StringLiteral *> stringLiterals;
  std::vector<std::tuple<KeywordItem *, std::shared_ptr<Function>>> kwargs;
  std::vector<FunctionExpression *> functionCalls;
  std::vector<MethodExpression *> methodCalls;

  FileMetadata() = default;

  FileMetadata(
      std::vector<IdExpression *> identifiers,
      std::vector<StringLiteral *> stringLiterals,
      std::vector<std::tuple<KeywordItem *, std::shared_ptr<Function>>> kwargs,
      std::vector<FunctionExpression *> functionCalls,
      std::vector<MethodExpression *> methodCalls)
      : identifiers(std::move(identifiers)),
        stringLiterals(std::move(stringLiterals)), kwargs(std::move(kwargs)),
        functionCalls(std::move(functionCalls)),
        methodCalls(std::move(methodCalls)) {}
};

class MesonMetadata {
public:
  // Sadly raw pointers due to only getting raw pointers to the
  // code visitor.
  std::map<std::filesystem::path, std::vector<std::string>> subdirCalls;
  std::map<std::filesystem::path, FileMetadata> fileMetadata;
  std::map<std::filesystem::path, std::vector<SubscriptExpression *>>
      arrayAccess;
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

  void registerDiagnostic(const std::filesystem::path &key,
                          const ParsingError &err) {
    auto diag = Diagnostic(Severity::ERROR, err.message, err.range);
    if (this->diagnostics.contains(key)) {
      this->diagnostics[key].push_back(diag);
    } else {
      this->diagnostics[key] = {diag};
    }
  }

  void registerDiagnostic(const Node *node, const Diagnostic &diag) {
    const auto &key = node->file->file;
    if (this->diagnostics.contains(key)) {
      this->diagnostics[key].push_back(diag);
    } else {
      this->diagnostics[key] = {diag};
    }
  }

  void registerSubdirCall(FunctionExpression *node,
                          const std::vector<std::string> &subdirs) {
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
    this->fileMetadata[path] =
        FileMetadata(this->idExprs.back(), this->tempStringLiterals.back(),
                     this->tempKwargs.back(), this->tempFuncCalls.back(),
                     this->tempMethodCalls.back());
    this->idExprs.pop_back();
    this->tempStringLiterals.pop_back();
    this->tempKwargs.pop_back();
    this->tempFuncCalls.pop_back();
    this->tempMethodCalls.pop_back();
  }

  void registerKwarg(KeywordItem *item, const std::shared_ptr<Function> &func) {
    this->tempKwargs.back().emplace_back(item, func);
  }

  FIND(MethodExpression, methodCalls)
  FIND(FunctionExpression, functionCalls)
  FIND_FULL3(IdExpression, identifiers)
  FIND_FULL(SubscriptExpression, arrayAccess)
  FIND_FULL3(StringLiteral, stringLiterals)

  FIND_FULL2(MethodExpression, methodCalls)
  FIND_FULL2(FunctionExpression, functionCalls)

  void clear() {
    this->fileMetadata = {};
    this->subdirCalls = {};
    this->arrayAccess = {};
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
