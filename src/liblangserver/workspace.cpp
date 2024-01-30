#include "workspace.hpp"

#include "analysisoptions.hpp"
#include "codeactionvisitor.hpp"
#include "completion.hpp"
#include "documentsymbolvisitor.hpp"
#include "foldingrangevisitor.hpp"
#include "hover.hpp"
#include "inlayhintvisitor.hpp"
#include "langserverutils.hpp"
#include "lsptypes.hpp"
#include "mesonmetadata.hpp"
#include "mesontree.hpp"
#include "node.hpp"
#include "semantictokensvisitor.hpp"
#include "typenamespace.hpp"

#include <algorithm>
#include <atomic>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <format>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <string>
#include <vector>

static std::optional<std::string>
extractOptionName(const FunctionExpression *fe, const MesonMetadata *metadata);

std::vector<MesonTree *> findTrees(const std::shared_ptr<MesonTree> &root) {
  std::vector<MesonTree *> ret;
  ret.emplace_back(root.get());
  for (const auto &subproj : root->state.subprojects) {
    if (subproj->tree) {
      auto recursiveTrees = findTrees(subproj->tree);
      ret.insert(ret.end(), recursiveTrees.begin(), recursiveTrees.end());
    }
  }
  return ret;
}

bool Workspace::owns(const std::filesystem::path &path) {
  this->smph.acquire();
  for (const auto &subTree : this->foundTrees) {
    if (subTree->ownedFiles.contains(path)) {
      this->smph.release();
      return true;
    }
  }
  this->smph.release();
  return false;
}

std::vector<InlayHint>
Workspace::inlayHints(const std::filesystem::path &path) {
  this->smph.acquire();
  for (const auto &subTree : this->foundTrees) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto ast = subTree->asts[path];
    if (ast.empty()) {
      continue;
    }
    auto visitor =
        InlayHintVisitor(this->options.removeDefaultTypesInInlayHints);
    ast.back()->visit(&visitor);
    this->smph.release();
    return visitor.hints;
  }
  this->smph.release();
  return {};
}

std::optional<Hover> Workspace::hover(const std::filesystem::path &path,
                                      const LSPPosition &position) {
  this->smph.acquire();
  for (const auto &subTree : this->foundTrees) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto metadata = subTree->metadata;
    auto feOpt = metadata.findFunctionExpressionAt(path, position.line,
                                                   position.character);
    if (feOpt.has_value()) {
      auto val =
          makeHoverForFunctionExpression(feOpt.value(), subTree->options);
      this->smph.release();
      return val;
    }
    auto meOpt = metadata.findMethodExpressionAt(path, position.line,
                                                 position.character);
    if (meOpt.has_value()) {
      auto val = makeHoverForMethodExpression(meOpt.value());
      this->smph.release();
      return val;
    }
    auto idExprOpt =
        metadata.findIdExpressionAt(path, position.line, position.character);
    if (idExprOpt.has_value()) {
      auto val = makeHoverForId(tree->ns, idExprOpt.value());
      this->smph.release();
      return val;
    }
    this->smph.release();
    return {};
  }
  this->smph.release();
  return std::nullopt;
}

std::vector<CodeAction> Workspace::codeAction(const std::filesystem::path &path,
                                              const LSPRange &range) {
  this->smph.acquire();
  for (const auto &subTree : this->foundTrees) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto ast = subTree->asts[path];
    if (ast.empty()) {
      continue;
    }
    auto visitor = CodeActionVisitor(range, pathToUrl(path), subTree);
    ast.back()->visit(&visitor);
    this->smph.release();
    return visitor.actions;
  }
  this->smph.release();
  return {};
}

std::vector<DocumentHighlight>
Workspace::highlight(const std::filesystem::path &path,
                     const LSPPosition &position) {
  this->smph.acquire();
  for (const auto &subTree : this->foundTrees) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto metadata = subTree->metadata;
    if (!metadata.identifiers.contains(path)) {
      continue;
    }
    auto idExpr =
        metadata.findIdExpressionAt(path, position.line, position.character);
    if (!idExpr) {
      this->smph.release();
      return {};
    }
    auto identifiers = metadata.identifiers[path];
    std::vector<DocumentHighlight> ret;
    for (const auto &toCheck : identifiers) {
      if (idExpr.value()->id != toCheck->id) {
        continue;
      }
      auto kind = DocumentHighlightKind::READ_KIND;
      const auto *ass = dynamic_cast<AssignmentStatement *>(toCheck->parent);
      if (ass && toCheck->equals(ass->lhs.get())) {
        kind = DocumentHighlightKind::WRITE_KIND;
      }
      const auto &loc = toCheck->location;
      auto range = LSPRange(LSPPosition(loc.startLine, loc.startColumn),
                            LSPPosition(loc.endLine, loc.endColumn));
      ret.emplace_back(range, kind);
    }
    this->smph.release();
    return ret;
  }
  this->smph.release();
  return {};
}

std::vector<uint64_t>
Workspace::semanticTokens(const std::filesystem::path &path) {
  this->smph.acquire();
  for (const auto &subTree : this->foundTrees) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto ast = subTree->asts[path];
    if (ast.empty()) {
      continue;
    }
    auto visitor = SemanticTokensVisitor();
    ast.back()->visit(&visitor);
    this->smph.release();
    return visitor.finish();
  }
  this->smph.release();
  return {};
}

static std::optional<std::string>
extractOptionName(const FunctionExpression *fe, const MesonMetadata *metadata) {
  const auto *al = dynamic_cast<const ArgumentList *>(fe->args.get());
  if (!al || al->args.empty()) {
    return std::nullopt;
  }
  const auto *nameSl = dynamic_cast<StringLiteral *>(al->args[0].get());
  if (!nameSl || !metadata->options.contains(nameSl->id)) {
    return std::nullopt;
  }
  return nameSl->id;
}

std::vector<LSPLocation>
Workspace::jumpToFunctionCall(const MesonMetadata *metadata,
                              const std::filesystem::path &path,
                              const LSPPosition &position) {
  for (const auto &funcCall : metadata->functionCalls.at(path)) {
    if (!MesonMetadata::contains(funcCall, position.line, position.character) ||
        funcCall->file->file != path) {
      continue;
    }
    if (funcCall->functionName() == "get_option" && funcCall->args) {
      const auto optionNameOpt = extractOptionName(funcCall, metadata);
      if (!optionNameOpt.has_value() ||
          !metadata->options.contains(optionNameOpt.value())) {
        continue;
      }
      const auto &[optionsPath, line, character] =
          metadata->options.at(optionNameOpt.value());
      LSPPosition const pos{line, character};
      LSPRange const range{pos, pos};
      return {{pathToUrl(optionsPath), range}};
    }
    if (funcCall->functionName() != "subdir") {
      return {};
    }
    const std::filesystem::path &key =
        std::format("{}-{}", funcCall->file->file.generic_string(),
                    funcCall->location.format());
    if (!metadata->subdirCalls.contains(key)) {
      return {};
    }
    const auto &set = metadata->subdirCalls.at(key);
    std::vector<std::string> sorted{set.begin(), set.end()};
    std::ranges::sort(sorted);
    std::vector<LSPLocation> ret;
    for (const auto &subdir : sorted) {
      auto subdirMesonPath = path.parent_path() / subdir / "meson.build";
      auto range = LSPRange(LSPPosition(0, 0), LSPPosition(0, 0));
      ret.emplace_back(pathToUrl(subdirMesonPath), range);
    }
    return ret;
  }
  return {};
}

std::vector<LSPLocation>
Workspace::jumpToIdentifier(const MesonMetadata *metadata,
                            const std::filesystem::path &path,
                            const LSPPosition &position) {
  auto foundMyself = false;
  std::string toFind;
  for (size_t i = metadata->encounteredIds.size() - 1;; i--) {
    if (i == (size_t)-1) {
      break;
    }
    const auto &idExpr = metadata->encounteredIds[i];
    if (idExpr->file->file == path &&
        MesonMetadata::contains(idExpr, position.line, position.character)) {
      foundMyself = true;
      toFind = idExpr->id;
    }
    if (!foundMyself || idExpr->id != toFind) {
      continue;
    }
    const auto *ass = dynamic_cast<AssignmentStatement *>(idExpr->parent);
    if (ass && ass->op == AssignmentOperator::EQUALS) {
      const auto *lhsIdExpr = dynamic_cast<IdExpression *>(ass->lhs.get());
      if (lhsIdExpr && lhsIdExpr->id == toFind) {
        return {
            LSPLocation(pathToUrl(idExpr->file->file), nodeToRange(idExpr))};
      }
    }
    if (dynamic_cast<IterationStatement *>(idExpr->parent)) {
      return {LSPLocation(pathToUrl(idExpr->file->file), nodeToRange(idExpr))};
    }
  }
  return {};
}

std::vector<LSPLocation> Workspace::jumpTo(const MesonMetadata *metadata,
                                           const std::filesystem::path &path,
                                           const LSPPosition &position) {
  const auto &toIdentifier =
      Workspace::jumpToIdentifier(metadata, path, position);
  if (!toIdentifier.empty()) {
    return toIdentifier;
  }
  if (!metadata->functionCalls.contains(path)) {
    return {};
  }
  return Workspace::jumpToFunctionCall(metadata, path, position);
}

std::vector<LSPLocation> Workspace::jumpTo(const std::filesystem::path &path,
                                           const LSPPosition &position) {
  this->smph.acquire();
  for (const auto &subTree : this->foundTrees) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    const auto &metadata = &subTree->metadata;
    const auto &ret = Workspace::jumpTo(metadata, path, position);
    smph.release();
    return ret;
  }
  this->smph.release();
  return {};
}

WorkspaceEdit Workspace::rename(const MesonMetadata &metadata,
                                const IdExpression *toRename,
                                const std::string &newName) {
  WorkspaceEdit ret;
  auto foundOurself = false;
  for (const auto &[identifierPath, identifiers] : metadata.identifiers) {
    auto url = pathToUrl(identifierPath);
    ret.changes[url] = {};
    for (const auto *identifier : identifiers) {
      auto equals = identifier->equals(toRename);
      if (identifier->id != toRename->id || (equals && foundOurself)) {
        continue;
      }
      if (equals) {
        foundOurself = true;
      }
      // TODO: Rename parent-project `get_variable`
      ret.changes[url].emplace_back(nodeToRange(identifier), newName);
    }
  }
  return ret;
}

std::optional<WorkspaceEdit>
Workspace::rename(const std::filesystem::path &path,
                  const RenameParams &params) {
  this->smph.acquire();
  for (const auto &subTree : this->foundTrees) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto metadata = subTree->metadata;
    auto toRenameOpt = metadata.findIdExpressionAt(path, params.position.line,
                                                   params.position.character);
    if (!toRenameOpt.has_value()) {
      this->smph.release();
      return std::nullopt;
    }
    const auto &ret =
        Workspace::rename(metadata, toRenameOpt.value(), params.newName);
    this->smph.release();
    return ret;
  }
  this->smph.release();
  return std::nullopt;
}

std::vector<FoldingRange>
Workspace::foldingRanges(const std::filesystem::path &path) {
  this->smph.acquire();
  for (const auto &subTree : this->foundTrees) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto ast = subTree->asts[path];
    if (ast.empty()) {
      continue;
    }
    auto visitor = FoldingRangeVisitor();
    ast.back()->visit(&visitor);
    this->smph.release();
    return visitor.ranges;
  }
  this->smph.release();
  return {};
}

std::vector<SymbolInformation>
Workspace::documentSymbols(const std::filesystem::path &path) {
  this->smph.acquire();
  for (const auto &subTree : this->foundTrees) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto ast = subTree->asts[path];
    if (ast.empty()) {
      continue;
    }
    auto visitor = DocumentSymbolVisitor();
    ast.back()->visit(&visitor);
    this->smph.release();
    return visitor.symbols;
  }
  this->smph.release();
  return {};
}

void Workspace::dropCache(const std::filesystem::path &path) {
  for (const auto &subTree : this->foundTrees) {
    if (!subTree->ownedFiles.contains(path) ||
        !subTree->overrides.contains(path)) {
      continue;
    }
    auto iter = subTree->overrides.find(path);
    subTree->overrides.erase(iter);
  }
}

std::map<std::filesystem::path, std::vector<LSPDiagnostic>>
Workspace::clearDiagnostics() {
  std::map<std::filesystem::path, std::vector<LSPDiagnostic>> ret;

  for (const auto &subTree : this->foundTrees) {
    const auto &metadata = subTree->metadata;
    for (const auto &[diagPath, _] : metadata.diagnostics) {
      if (!ret.contains(diagPath)) {
        ret[diagPath] = {};
      }
    }
  }
  return ret;
}

std::optional<std::filesystem::path>
Workspace::muonConfigFile(const std::filesystem::path &path) {
  for (const auto &subTree : this->foundTrees) {
    const auto &treePath = subTree->root;
    if (std::filesystem::relative(path, treePath)
            .generic_string()
            .contains("..")) {
      continue;
    }
    auto iniFile = treePath / "muon_fmt.ini";
    if (std::filesystem::exists(iniFile)) {
      return iniFile;
    }
    break;
  }
  return std::nullopt;
}

std::map<std::filesystem::path, std::vector<LSPDiagnostic>>
Workspace::fullReparse(const TypeNamespace &ns) {
  auto newTree = std::make_shared<MesonTree>(this->root, ns);
  newTree->fullParse(this->options.analysisOptions,
                     !this->options.neverDownloadAutomatically);
  newTree->identifier = this->name;
  this->tree = newTree;
  this->foundTrees = findTrees(this->tree);
  std::map<std::filesystem::path, std::vector<LSPDiagnostic>> ret;
  for (const auto &subTree : this->foundTrees) {
    const auto &metadata = subTree->metadata;
    if (subTree->depth > 0 &&
        this->options.ignoreDiagnosticsFromSubprojects.has_value()) {
      const auto &toIgnore = this->options.ignoreDiagnosticsFromSubprojects;
      if (toIgnore->empty()) {
        continue; // Skip every subproject
      }
      if (std::ranges::find(toIgnore.value(), subTree->name) !=
          toIgnore->end()) {
        continue;
      }
    }
    for (const auto &[diagPath, diags] : metadata.diagnostics) {
      if (!ret.contains(diagPath)) {
        ret[diagPath] = {};
      }
      for (const auto &diag : diags) {
        ret[diagPath].push_back(makeLSPDiagnostic(diag));
      }
    }
  }
  return ret;
}

std::map<std::filesystem::path, std::vector<LSPDiagnostic>>
Workspace::parse(const TypeNamespace &ns) {
  this->settingUp = true;
  auto newTree = std::make_shared<MesonTree>(this->root, ns);
  newTree->fullParse(this->options.analysisOptions,
                     !this->options.neverDownloadAutomatically);
  newTree->identifier = this->name;
  this->tree = newTree;
  this->foundTrees = findTrees(this->tree);
  std::map<std::filesystem::path, std::vector<LSPDiagnostic>> ret;
  for (const auto &subTree : this->foundTrees) {
    const auto &metadata = subTree->metadata;
    if (subTree->depth > 0 &&
        this->options.ignoreDiagnosticsFromSubprojects.has_value()) {
      const auto &toIgnore = this->options.ignoreDiagnosticsFromSubprojects;
      if (toIgnore->empty()) {
        continue; // Skip every subproject
      }
      if (std::ranges::find(toIgnore.value(), subTree->name) !=
          toIgnore->end()) {
        continue;
      }
    }
    for (const auto &[diagPath, diags] : metadata.diagnostics) {
      if (!ret.contains(diagPath)) {
        ret[diagPath] = {};
      }
      for (const auto &diag : diags) {
        ret[diagPath].push_back(makeLSPDiagnostic(diag));
      }
    }
  }
  this->settingUp = false;
  return ret;
}

std::vector<CompletionItem>
Workspace::completion(const std::filesystem::path &path,
                      const LSPPosition &position) {
  this->smph.acquire();
  this->completing = true;

  for (const auto &subTree : this->foundTrees) {
    if (!subTree->ownedFiles.contains(path)) {
      continue;
    }
    auto ret = complete(path, subTree, subTree->asts[path].back(), position);
    this->completing = false;
    this->smph.release();
    this->logger.info(std::format("Created {} completions", ret.size()));
    return ret;
  }

  this->completing = false;
  this->smph.release();
  return {};
}
