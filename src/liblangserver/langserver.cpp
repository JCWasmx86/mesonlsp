#include "langserver.hpp"

#include "langserverutils.hpp"
#include "libpkgconf/iter.h"
#include "log.hpp"
#include "lsptypes.hpp"
#include "utils.hpp"
#include "workspace.hpp"

#include <cassert>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <format>
#include <fstream>
#include <map>
#include <memory>
#include <optional>
#include <ostream>
#include <pkgconf/libpkgconf/libpkgconf.h>
#include <string>
#include <vector>
extern "C" {
#include <lang/fmt.h>
#include <log.h>
#include <platform/filesystem.h>
#include <platform/init.h>
}

static Logger LOG("LanguageServer"); // NOLINT

std::filesystem::path writeMuonConfigFile(FormattingOptions options) {
  const auto &name =
      std::format("muon-fmt-{}-{}", options.insertSpaces, options.tabSize);
  const auto &fullPath = cacheDir() / name;
  if (std::filesystem::exists(fullPath)) {
    return fullPath;
  }
  const auto &indent =
      options.insertSpaces ? std::string(options.tabSize, ' ') : "\t";
  const auto &contents = std::format("indent_by = '{}'\n", indent);
  std::ofstream fileStream(fullPath);
  assert(fileStream.is_open());
  fileStream << contents << std::endl;
  fileStream.close();
  return fullPath;
}

extern "C" {
static bool pkgconfLogHandler(const char *msg, const pkgconf_client_t *client,
                              const void *data) {
  (void)client;
  (void)data;
  (void)msg;
  return true;
}
}

LanguageServer::LanguageServer() {
  auto *personality = pkgconf_cross_personality_default();
  pkgconf_list_t dirList = PKGCONF_LIST_INITIALIZER;
  pkgconf_path_copy_list(&personality->dir_list, &dirList);
  pkgconf_path_free(&dirList);
  pkgconf_client_t pkgClient;
  memset(&pkgClient, 0, sizeof(pkgClient));
  pkgconf_client_set_trace_handler(&pkgClient, nullptr, nullptr);
  pkgconf_client_set_sysroot_dir(&pkgClient, nullptr);
  pkgconf_client_init(&pkgClient,
                      (pkgconf_error_handler_func_t)pkgconfLogHandler, nullptr,
                      personality);
  pkgconf_client_set_trace_handler(
      &pkgClient, (pkgconf_error_handler_func_t)pkgconfLogHandler, nullptr);
  pkgconf_client_set_flags(&pkgClient, PKGCONF_PKG_PKGF_NONE);
  pkgconf_client_dir_list_build(&pkgClient, personality);
  pkgconf_scan_all(&pkgClient, this,
                   [](const pkgconf_pkg_t *entry, void *data) {
                     if ((entry->flags & PKGCONF_PKG_PROPF_UNINSTALLED) != 0U) {
                       return false;
                     }
                     std::string const pkgName{entry->id};
                     LOG.info("Found package: " + pkgName);
                     ((LanguageServer *)data)->pkgNames.insert(pkgName);
                     return false;
                   });
  pkgconf_cross_personality_deinit(personality);
  pkgconf_client_deinit(&pkgClient);
}

void LanguageServer::onDidChangeConfiguration(
    DidChangeConfigurationParams &params) {
  this->options.update(params.settings);
  for (auto &workspace : this->workspaces) {
    const auto &oldDiags = workspace->clearDiagnostics();
    workspace->options = this->options;
    this->publishDiagnostics(oldDiags);
    const auto &diags = workspace->parse(this->ns);
    this->publishDiagnostics(diags);
  }
}

InitializeResult LanguageServer::initialize(InitializeParams &params) {
  platform_init();
  log_init();

  this->options.update(params.initializationOptions);

  for (const auto &wspf : params.workspaceFolders) {
    auto workspace = std::make_shared<Workspace>(wspf, this->options);
    const auto &diags = workspace->parse(this->ns);
    this->diagnosticsFromInitialisation.emplace_back(diags);
    this->workspaces.push_back(workspace);
  }
  return {ServerCapabilities(
              TextDocumentSyncOptions(true, TextDocumentSyncKind::Full), true,
              true, true, true, true, true, true, true, true, true,
              CompletionOptions(false, {".", "_", ")"}),
              SemanticTokensOptions(
                  true, SemanticTokensLegend({"substitute", "substitute_bounds",
                                              "variable", "function", "method",
                                              "keyword", "string", "number"},
                                             {"readonly", "defaultLibrary"}))),
          ServerInfo("c++-mesonlsp", VERSION)};
}

void LanguageServer::shutdown() {}

void LanguageServer::onInitialized(InitializedParams & /*params*/) {
  for (const auto &map : this->diagnosticsFromInitialisation) {
    this->publishDiagnostics(map);
  }
  this->diagnosticsFromInitialisation.clear();
}

void LanguageServer::onExit() {}

void LanguageServer::onDidOpenTextDocument(
    DidOpenTextDocumentParams & /*params*/) {}

void LanguageServer::onDidChangeTextDocument(
    DidChangeTextDocumentParams &params) {
  this->smph.acquire();
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  this->cachedContents[path] = params.contentChanges[0].text;
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      LOG.info(std::format("Patching file {} for workspace {}",
                           path.generic_string(), workspace->name));
      workspace->patchFile(
          path, params.contentChanges[0].text,
          [this](
              const std::map<std::filesystem::path, std::vector<LSPDiagnostic>>
                  &changes) { this->publishDiagnostics(changes); });
      this->smph.release();
      return;
    }
  }
  this->smph.release();
}

std::vector<InlayHint> LanguageServer::inlayHints(InlayHintParams &params) {
  if (this->options.disableInlayHints) {
    return {};
  }
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->inlayHints(path);
    }
  }
  return {};
}

std::vector<SymbolInformation>
LanguageServer::documentSymbols(DocumentSymbolParams &params) {
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->documentSymbols(path);
    }
  }
  return {};
}

TextEdit LanguageServer::formatting(DocumentFormattingParams &params) {
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  const auto &toFormat = this->cachedContents.contains(path)
                             ? this->cachedContents[path]
                             : readFile(path);
  std::filesystem::path configFile;
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      if (auto file = workspace->muonConfigFile(path)) {
        configFile = file.value();
      }
    }
  }
  if (configFile.empty()) {
    configFile = writeMuonConfigFile(params.options);
  }
  struct source src = {.label = path.c_str(),
                       .src = strdup(toFormat.data()),
                       .len = toFormat.size(),
                       .reopen_type = source_reopen_type_none};
  char *formattedStr;
  size_t formattedSize;
  auto *output = open_memstream(&formattedStr, &formattedSize);
  auto fmtRet = fmt(&src, output, configFile.c_str(), false, true);
  if (!fmtRet) {
    (void)fclose(output);
    free((void *)src.src);
    free(formattedStr);
    LOG.error("Failed to format");
    throw "Failed to format";
  }
  (void)fflush(output);
  (void)fclose(output);
  std::string const asString(static_cast<const char *>(formattedStr),
                             formattedSize);

  // Editors don't care, if we tell them, that the file is
  // a lot longer than it really is, so we just guess some
  // number of lines.
  auto guesstimatedLines = (toFormat.size() / 40) * 10;
  auto edit = TextEdit(
      LSPRange(LSPPosition(0, 0), LSPPosition(guesstimatedLines, 2000)),
      std::string(asString));
  free(formattedStr);
  return edit;
}

std::vector<uint64_t>
LanguageServer::semanticTokens(SemanticTokensParams &params) {
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->semanticTokens(path);
    }
  }
  return {};
}

std::vector<DocumentHighlight>
LanguageServer::highlight(DocumentHighlightParams &params) {
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->highlight(path, params.position);
    }
  }
  return {};
}

std::optional<WorkspaceEdit> LanguageServer::rename(RenameParams &params) {
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->rename(path, params);
    }
  }
  return std::nullopt;
}

std::vector<LSPLocation>
LanguageServer::declaration(DeclarationParams &params) {
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->jumpTo(path, params.position);
    }
  }
  return {};
}

std::vector<LSPLocation> LanguageServer::definition(DefinitionParams &params) {
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->jumpTo(path, params.position);
    }
  }
  return {};
}

std::vector<CodeAction> LanguageServer::codeAction(CodeActionParams &params) {
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->codeAction(path, params.range);
    }
  }
  return {};
}

std::vector<FoldingRange>
LanguageServer::foldingRanges(FoldingRangeParams &params) {
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->foldingRanges(path);
    }
  }
  return {};
}

std::optional<Hover> LanguageServer::hover(HoverParams &params) {
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->hover(path, params.position);
    }
  }
  return std::nullopt;
}

void LanguageServer::onDidSaveTextDocument(
    DidSaveTextDocumentParams & /*params*/) {}

void LanguageServer::onDidCloseTextDocument(
    DidCloseTextDocumentParams &params) {
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  if (this->cachedContents.contains(path)) {
    const auto &iter = this->cachedContents.find(path);
    this->cachedContents.erase(iter);
  }
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      workspace->dropCache(path);
      return;
    }
  }
}

std::vector<CompletionItem>
LanguageServer::completion(CompletionParams &params) {
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->completion(path, params.position);
    }
  }
  return {};
}

void LanguageServer::publishDiagnostics(
    const std::map<std::filesystem::path, std::vector<LSPDiagnostic>>
        &newDiags) {
  for (const auto &pair : newDiags) {
    const auto &asURI = pathToUrl(pair.first);
    const auto &clearingParams = PublishDiagnosticsParams(asURI, {});
    this->server->notification("textDocument/publishDiagnostics",
                               clearingParams.toJson());
    const auto &newParams = PublishDiagnosticsParams(asURI, pair.second);
    this->server->notification("textDocument/publishDiagnostics",
                               newParams.toJson());
    LOG.info(std::format("Publishing {} diagnostics for {}", pair.second.size(),
                         pair.first.generic_string()));
  }
}
