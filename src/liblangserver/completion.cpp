#include "completion.hpp"

#include "argument.hpp"
#include "function.hpp"
#include "langserverutils.hpp"
#include "log.hpp"
#include "lsptypes.hpp"
#include "mesontree.hpp"
#include "node.hpp"
#include "type.hpp"
#include "typeanalyzer.hpp"
#include "utils.hpp"

#include <cassert>
#include <cctype>
#include <cstdint>
#include <filesystem>
#include <format>
#include <memory>
#include <optional>
#include <set>
#include <string>
#include <vector>

const static Logger LOG("Completion"); // NOLINT

static std::optional<std::vector<std::shared_ptr<Type>>>
afterDotCompletion(MesonTree *tree, const std::filesystem::path &path,
                   uint64_t line, uint64_t character, bool recurse);
static std::optional<std::string> extractErrorId(const std::string &prev);
static std::set<std::shared_ptr<Method>>
fillTypes(const MesonTree *tree,
          const std::vector<std::shared_ptr<Type>> &types);
static std::string createTextForFunction(const std::shared_ptr<Function> &func);
static void
specialStringLiteralAutoCompletion(MesonTree *tree, StringLiteral *literal,
                                   std::vector<CompletionItem> &ret);

std::vector<CompletionItem> complete(const std::filesystem::path &path,
                                     MesonTree *tree,
                                     const std::shared_ptr<Node> &ast,
                                     const LSPPosition &position) {
  auto lines = split(ast->file->contents(), "\n");
  lines.emplace_back("\n");
  std::vector<CompletionItem> ret;
  if (position.line >= lines.size()) {
    LOG.warn(
        std::format("Completion OOB: {} >= {}", position.line, lines.size()));
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
    if (types.has_value() && !types.value().empty()) {
      LOG.info(std::format("Guessed types in afterDotCompletion: {}",
                           joinTypes(types.value())));
      const auto *toAdd = lastCharSeen == '.' ? "" : ".";
      for (const auto &method : fillTypes(tree, types.value())) {
        ret.emplace_back(toAdd + method->name + "()",
                         CompletionItemKind::CIKMethod,
                         TextEdit({position, position},
                                  toAdd + createTextForFunction(method)));
      }
    } else {
      auto errorId = extractErrorId(prev);
      if (!errorId.has_value() || errorId.value().empty()) {
        goto next;
      }
      LOG.info(std::format("ErrorID: '{}'", errorId.value()));
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
    LOG.info(std::format("Found idExpr: {} at {}", idExpr->id,
                         idExpr->location.format()));
    const auto *parent = idExpr->parent;
    auto rightParent =
        (dynamic_cast<const BuildDefinition *>(parent) != nullptr) ||
        (dynamic_cast<const SelectionStatement *>(parent) != nullptr) ||
        (dynamic_cast<const IterationStatement *>(parent) != nullptr) ||
        (dynamic_cast<const ArgumentList *>(parent) != nullptr) ||
        (dynamic_cast<const BinaryExpression *>(parent) != nullptr) ||
        (dynamic_cast<const UnaryExpression *>(parent) != nullptr) ||
        (dynamic_cast<const AssignmentStatement *>(parent) != nullptr);
    const auto &loweredId = lowercase(idExpr->id);
    std::set<std::string> toInsert;
    for (const auto &identifier : tree->metadata.encounteredIds) {
      if (identifier->file->file == path &&
          identifier->location.startLine > position.line) {
        break;
      }
      if (lowercase(identifier->id).contains(loweredId) &&
          loweredId != identifier->id) {
        toInsert.insert(identifier->id);
      }
    }
    for (const auto &identifier : toInsert) {
      auto kind = CompletionItemKind::CIKVariable;
      if (identifier == "meson" || identifier == "build_machine" ||
          identifier == "host_machine" || identifier == "target_machine") {
        kind = CompletionItemKind::CIKConstant;
      }
      ret.emplace_back(identifier, kind,
                       TextEdit(nodeToRange(idExpr), identifier));
    }
    const ArgumentList *al = nullptr;
    if (!rightParent) {
      goto insertFns;
    }
    al = dynamic_cast<const ArgumentList *>(parent);
    if (al) {
      const auto *parentOfArgs = al->parent;
      assert(parentOfArgs);
      std::shared_ptr<Function> func;
      const auto *fe = dynamic_cast<const FunctionExpression *>(parentOfArgs);
      if (fe) {
        func = fe->function;
      }
      const auto *me = dynamic_cast<const MethodExpression *>(parentOfArgs);
      if (me) {
        func = me->method;
      }
      if (!func) {
        goto insertFns;
      }
      std::set<std::string> unusedKwargs;
      for (const auto &kwarg : func->kwargs) {
        unusedKwargs.insert(kwarg.first);
      }
      for (const auto &arg : al->args) {
        const auto *kwarg = dynamic_cast<KeywordItem *>(arg.get());
        if (!kwarg || !kwarg->name.has_value()) {
          continue;
        }
        const auto &val = kwarg->name.value();
        if (unusedKwargs.contains(val)) {
          unusedKwargs.erase(val);
        }
      }
      for (const auto &toAdd : unusedKwargs) {
        ret.emplace_back(toAdd, CompletionItemKind::CIKKeyword,
                         TextEdit(nodeToRange(idExpr),
                                  std::format("{}: ${{1:{}}}", toAdd, toAdd)));
      }
    }
  insertFns:
    for (const auto &function : tree->ns.functions) {
      auto lowerName = lowercase(function.first);
      if (lowerName.contains(loweredId)) {
        ret.emplace_back(function.first + "()", CompletionItemKind::CIKFunction,
                         TextEdit(nodeToRange(idExpr),
                                  createTextForFunction(function.second)));
      }
    }
  } else if (prev.empty()) {
    for (const auto &function : tree->ns.functions) {
      ret.emplace_back(function.first + "()", CompletionItemKind::CIKFunction,
                       TextEdit(LSPRange(position, position),
                                createTextForFunction(function.second)));
    }
  }
  auto slAtPos = tree->metadata.findStringLiteralAt(path, position.line,
                                                    position.character);
  if (slAtPos.has_value()) {
    LOG.info("Found string literal");
    specialStringLiteralAutoCompletion(tree, slAtPos.value(), ret);
  }
  return ret;
}

static std::optional<std::vector<std::shared_ptr<Type>>>
afterDotCompletion(MesonTree *tree, const std::filesystem::path &path,
                   uint64_t line, uint64_t character, bool recurse) {
  auto idExprOpt = tree->metadata.findIdExpressionAt(path, line, character);
  if (idExprOpt.has_value()) {
    LOG.info(std::format("Found identifier {}", idExprOpt.value()->id));
    return idExprOpt.value()->types;
  }
  auto fExprOpt =
      tree->metadata.findFullFunctionExpressionAt(path, line, character - 1);
  if (fExprOpt.has_value() && fExprOpt.value()->function) {
    LOG.info(
        std::format("Found func call {}", fExprOpt.value()->function->id()));
    return fExprOpt.value()->types;
  }
  auto mExprOpt =
      tree->metadata.findFullMethodExpressionAt(path, line, character - 1);
  if (mExprOpt.has_value() && mExprOpt.value()->method) {
    LOG.info(
        std::format("Found method call {}", mExprOpt.value()->method->id()));
    return mExprOpt.value()->types;
  }
  auto sseOpt =
      tree->metadata.findSubscriptExpressionAt(path, line, character - 1);
  if (sseOpt.has_value()) {
    LOG.info(std::format("Found subscript expression {}",
                         sseOpt.value()->location.format()));
    return sseOpt.value()->types;
  }
  auto stringLit = tree->metadata.findStringLiteralAt(path, line, character);
  if (stringLit.has_value()) {
    LOG.info(std::format("Found string literal {}",
                         stringLit.value()->location.format()));
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

static void
specialStringLiteralAutoCompletion(MesonTree *tree, StringLiteral *literal,
                                   std::vector<CompletionItem> &ret) {
  auto *parent = literal->parent;
  auto *al = dynamic_cast<ArgumentList *>(parent);
  // TODO: Maybe check kwargs?
  if (!al) {
    LOG.info("Auto-completion in string literal => No argument list as parent");
    return;
  }
  auto *fe = dynamic_cast<FunctionExpression *>(al->parent);
  if (fe && fe->function) {
    const auto &func = fe->function;
    LOG.info("Found function: " + func->id());
    // dependency, get_option
    if (func->name == "files") {
      std::set<std::filesystem::path> alreadyExisting;
      const auto ppath = literal->file->file.parent_path();
      for (const auto &arg : al->args) {
        if (dynamic_cast<const KeywordItem *>(arg.get())) {
          continue;
        }
        const auto *sl = dynamic_cast<const StringLiteral *>(arg.get());
        if (!sl || sl->equals(literal)) {
          continue;
        }
        const auto &fullPath = std::filesystem::absolute(ppath / sl->id);
        LOG.info(std::format("Found path: {}", fullPath.generic_string()));
        alreadyExisting.insert(fullPath);
      }
      const auto &toSearch =
          !literal->id.contains("/")
              ? ppath
              : ppath / literal->id.substr(0, literal->id.rfind('/'));
      if (!std::filesystem::exists(toSearch)) {
        return;
      }
      for (const auto &entry : std::filesystem::directory_iterator{toSearch}) {
        const auto &fullPath = std::filesystem::absolute(entry.path());
        if (!std::filesystem::is_regular_file(fullPath)) {
          continue;
        }
        if (alreadyExisting.contains(fullPath)) {
          LOG.info(std::format("Skipping path: {}", fullPath.generic_string()));
          continue;
        }
        const auto &relative =
            fullPath.lexically_relative(ppath).generic_string();
        LOG.info(std::format("Adding path: {}", relative));
        // TODO: Works in Builder, but not in VSCode
        ret.emplace_back(
            relative, CompletionItemKind::CIKFile,
            TextEdit(nodeToRange(literal), std::format("{}", relative)));
      }
    }

    if (func->name == "get_option") {
      for (const auto &opt : tree->options.options) {
        LOG.info(std::format("Inserting option {}", opt->name));
        // TODO: Works in Builder, but not in VSCode
        ret.emplace_back(
            opt->name, CompletionItemKind::CIKFile,
            TextEdit(nodeToRange(literal), std::format("{}", opt->name)));
      }
    }

    return;
  }
  auto *me = dynamic_cast<MethodExpression *>(al->parent);
  if (!me || !me->method) {
    return;
  }
}
