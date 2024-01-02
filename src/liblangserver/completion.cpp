#include "completion.hpp"

#include "argument.hpp"
#include "function.hpp"
#include "langserverutils.hpp"
#include "log.hpp"
#include "lsptypes.hpp"
#include "mesontree.hpp"
#include "node.hpp"
#include "type.hpp"
#include "utils.hpp"

#include <cctype>
#include <cstdint>
#include <filesystem>
#include <format>
#include <memory>
#include <optional>
#include <set>
#include <string>
#include <vector>

static Logger LOG("Completion"); // NOLINT

static std::optional<std::vector<std::shared_ptr<Type>>>
afterDotCompletion(MesonTree *tree, const std::filesystem::path &path,
                   uint64_t line, uint64_t character, bool recurse);
static std::optional<std::string> extractErrorId(const std::string &prev);
static std::set<std::shared_ptr<Method>>
fillTypes(const MesonTree *tree,
          const std::vector<std::shared_ptr<Type>> &types);
static std::string createTextForFunction(const std::shared_ptr<Function> &func);

std::vector<CompletionItem> complete(const std::filesystem::path &path,
                                     MesonTree *tree,
                                     const std::shared_ptr<Node> &ast,
                                     const LSPPosition &position) {
  const auto lines = split(ast->file->contents(), "\n");
  std::vector<CompletionItem> ret;
  if (position.line > lines.size()) {
    return {};
  }
  const auto &line = lines[position.line];
  auto prev = line.substr(0, position.character);
  if (!prev.empty()) {
    auto lastCharSeen = prev.back();
    if (lastCharSeen != '.' && lastCharSeen != ')') {
      goto next;
    }
    auto types =
        afterDotCompletion(tree, path, position.line, position.character, true);
    if (types.has_value()) {
      const auto *toAdd = lastCharSeen == '.' ? "" : ".";
      for (const auto &method : fillTypes(tree, types.value())) {
        ret.emplace_back(toAdd + method->name + "()",
                         CompletionItemKind::CIKMethod,
                         TextEdit({position, position},
                                  toAdd + createTextForFunction(method)));
      }
    } else {
      auto errorId = extractErrorId(prev);
      if (!errorId.has_value()) {
        goto next;
      }
      std::vector<std::shared_ptr<Type>> types;
      for (auto *const identifier : tree->metadata.identifiers[path]) {
        types.insert(types.end(), identifier->types.begin(),
                     identifier->types.end());
      }
      for (const auto &method : fillTypes(tree, types)) {
        ret.emplace_back("." + method->name + "()",
                         CompletionItemKind::CIKMethod,
                         TextEdit({position, position},
                                  "." + createTextForFunction(method)));
      }
    }
  }
next:
  auto idExprAtPos = tree->metadata.findIdExpressionAt(path, position.line,
                                                       position.character);
  if (idExprAtPos.has_value()) {
    const auto *idExpr = idExprAtPos.value();
    const auto *parent = idExpr->parent;
    auto rightParent =
        (dynamic_cast<const BuildDefinition *>(parent) != nullptr) ||
        (dynamic_cast<const SelectionStatement *>(parent) != nullptr) ||
        (dynamic_cast<const IterationStatement *>(parent) != nullptr) ||
        (dynamic_cast<const ArgumentList *>(parent) != nullptr) ||
        (dynamic_cast<const BinaryExpression *>(parent) != nullptr) ||
        (dynamic_cast<const UnaryExpression *>(parent) != nullptr) ||
        (dynamic_cast<const AssignmentStatement *>(parent) != nullptr);
    if (!rightParent) {
      goto next;
    }
    auto loweredId = lowercase(idExpr->id);
    for (const auto &function : tree->ns.functions) {
      auto lowerName = lowercase(function.first);
      if (lowerName.contains(loweredId)) {
        ret.emplace_back(function.first + "()", CompletionItemKind::CIKFunction,
                         TextEdit(nodeToRange(idExpr),
                                  createTextForFunction(function.second)));
      }
    }
  }
  return ret;
}

static std::optional<std::vector<std::shared_ptr<Type>>>
afterDotCompletion(MesonTree *tree, const std::filesystem::path &path,
                   uint64_t line, uint64_t character, bool recurse) {
  auto idExprOpt = tree->metadata.findIdExpressionAt(path, line, character);
  if (idExprOpt.has_value()) {
    return idExprOpt.value()->types;
  }
  auto fExprOpt =
      tree->metadata.findFullFunctionExpressionAt(path, line, character - 1);
  if (fExprOpt.has_value() && fExprOpt.value()->function) {
    return fExprOpt.value()->types;
  }
  auto mExprOpt =
      tree->metadata.findFullMethodExpressionAt(path, line, character - 1);
  if (mExprOpt.has_value() && mExprOpt.value()->method) {
    return mExprOpt.value()->types;
  }
  auto sseOpt =
      tree->metadata.findSubscriptExpressionAt(path, line, character - 1);
  if (sseOpt.has_value()) {
    return sseOpt.value()->types;
  }
  auto stringLit = tree->metadata.findStringLiteralAt(path, line, character);
  if (stringLit.has_value()) {
    return stringLit.value()->types;
  }
  if (recurse && character > 0) {
    return afterDotCompletion(tree, path, line, character - 1, false);
  }
  return std::nullopt;
}

std::set<std::shared_ptr<Method>>
fillTypes(const MesonTree *tree,
          const std::vector<std::shared_ptr<Type>> &types) {
  std::set<std::shared_ptr<Method>> ret;
  for (const auto &type : types) {
    if (!tree->ns.vtables.contains(type->name)) {
      continue;
    }
    auto methods = tree->ns.vtables.at(type->name);
    ret.insert(methods.begin(), methods.end());
  }
  return ret;
}

static std::string
createTextForFunction(const std::shared_ptr<Function> &func) {
  std::string ret = std::format("{}(", func->name);
  auto templateIdx = 1;
  for (const auto &arg : func->args) {
    const auto *const posArg =
        dynamic_cast<const PositionalArgument *>(arg.get());
    if (!posArg) {
      continue;
    }
    if (!posArg->optional) {
      ret += std::format("${{{}:{}}}, ", templateIdx, posArg->name);
      templateIdx++;
    }
  }
  for (const auto &arg : func->args) {
    const auto *const kwarg = dynamic_cast<const Kwarg *>(arg.get());
    if (!kwarg) {
      continue;
    }
    if (!kwarg->optional) {
      ret += std::format("{}: ${{{}:{}}}, ", kwarg->name, templateIdx,
                         kwarg->name);
      templateIdx++;
    }
  }
  ret += ")";
  replace(ret, ", )", ")");
  return ret;
}

static std::optional<std::string> extractErrorId(const std::string &prev) {
  if (prev.empty()) {
    return std::nullopt;
  }
  std::string ret;
  auto idx = prev.size() - 1;
  while (idx > 0) {
    idx--;
    auto chr = prev[idx];
    if (std::isblank(chr) != 0) {
      return ret;
    }
    if ((std::isalnum(chr) != 0) || chr == '_') {
      ret = std::format("{}{}", chr, ret);
      continue;
    }
    return ret;
  }
  return ret;
}
