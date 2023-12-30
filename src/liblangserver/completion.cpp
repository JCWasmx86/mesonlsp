#include "completion.hpp"

#include "argument.hpp"
#include "function.hpp"
#include "log.hpp"
#include "lsptypes.hpp"
#include "utils.hpp"

#include <cstdint>
#include <format>
#include <memory>

static Logger LOG("Completion"); // NOLINT

static std::optional<std::vector<std::shared_ptr<Type>>>
afterDotCompletion(const std::shared_ptr<MesonTree> &tree,
                   const std::filesystem::path &path, uint64_t line,
                   uint64_t character, bool recurse);
static std::set<std::shared_ptr<Method>>
fillTypes(const std::shared_ptr<MesonTree> &tree,
          std::vector<std::shared_ptr<Type>> types);
static std::string createTextForFunction(std::shared_ptr<Function> func);

std::vector<CompletionItem> complete(const std::filesystem::path &path,
                                     const std::shared_ptr<MesonTree> &tree,
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
      for (const auto &method : fillTypes(tree, types.value())) {
        ret.emplace_back(
            method->name, CompletionItemKind::CIKMethod,
            TextEdit({position, position}, createTextForFunction(method)));
      }
    }
  }
next:
  return ret;
}

static std::optional<std::vector<std::shared_ptr<Type>>>
afterDotCompletion(const std::shared_ptr<MesonTree> &tree,
                   const std::filesystem::path &path, uint64_t line,
                   uint64_t character, bool recurse) {
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
fillTypes(const std::shared_ptr<MesonTree> &tree,
          std::vector<std::shared_ptr<Type>> types) {
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

static std::string createTextForFunction(std::shared_ptr<Function> func) {
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
      ret += std::format("{}: ${{{}:{}}}, ", kwarg->name, templateIdx, kwarg->name);
      templateIdx++;
    }
  }
  ret += ")";
  replace(ret, ", )", ")");
  return ret;
}
