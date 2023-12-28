#include "langserver.hpp"

#include "langserverutils.hpp"
#include "log.hpp"
#include "lsptypes.hpp"
#include "utils.hpp"
#include "workspace.hpp"

#include <cassert>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <format>
#include <optional>
extern "C" {
#include <lang/fmt.h>
#include <log.h>
#include <platform/filesystem.h>
#include <platform/init.h>
}

static Logger LOG("LanguageServer"); // NOLINT

std::filesystem::path writeMuonConfigFile(FormattingOptions options) {
  auto name =
      std::format("muon-fmt-{}-{}", options.insertSpaces, options.tabSize);
  auto fullPath = cacheDir() / name;
  if (std::filesystem::exists(fullPath)) {
    return fullPath;
  }
  auto indent = options.insertSpaces ? std::string(options.tabSize, ' ') : "\t";
  auto contents = std::format("indent_by = '{}'\n", indent);
  std::ofstream fileStream(fullPath);
  assert(fileStream.is_open());
  fileStream << contents << std::endl;
  fileStream.close();
  return fullPath;
}

InitializeResult LanguageServer::initialize(InitializeParams &params) {
  platform_init();
  log_init();

  for (auto wspf : params.workspaceFolders) {
    auto workspace = std::make_shared<Workspace>(wspf);
    auto diags = workspace->parse(this->ns);
    this->diagnosticsFromInitialisation.emplace_back(diags);
    this->workspaces.push_back(workspace);
  }
  return {ServerCapabilities(
              TextDocumentSyncOptions(true, TextDocumentSyncKind::Full), true,
              true, true, true, true, true, true, true, true, true, true,
              CompletionOptions(false, {".", "_"}),
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

void LanguageServer::onDidOpenTextDocument(DidOpenTextDocumentParams &params) {}

void LanguageServer::onDidChangeTextDocument(
    DidChangeTextDocumentParams &params) {
  auto path = extractPathFromUrl(params.textDocument.uri);
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
      return;
    }
  }
}

std::vector<InlayHint> LanguageServer::inlayHints(InlayHintParams &params) {
  auto path = extractPathFromUrl(params.textDocument.uri);
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->inlayHints(path);
    }
  }
  return {};
}

std::vector<SymbolInformation>
LanguageServer::documentSymbols(DocumentSymbolParams &params) {
  auto path = extractPathFromUrl(params.textDocument.uri);
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->documentSymbols(path);
    }
  }
  return {};
}

TextEdit LanguageServer::formatting(DocumentFormattingParams &params) {
  auto path = extractPathFromUrl(params.textDocument.uri);
  auto toFormat = this->cachedContents.contains(path)
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
  std::string asString(static_cast<const char *>(formattedStr), formattedSize);

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
  auto path = extractPathFromUrl(params.textDocument.uri);
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->semanticTokens(path);
    }
  }
  return {};
}

std::vector<DocumentHighlight>
LanguageServer::highlight(DocumentHighlightParams &params) {
  auto path = extractPathFromUrl(params.textDocument.uri);
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->highlight(path, params.position);
    }
  }
  return {};
}

std::optional<WorkspaceEdit> LanguageServer::rename(RenameParams &params) {
  auto path = extractPathFromUrl(params.textDocument.uri);
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->rename(path, params);
    }
  }
  return std::nullopt;
}

std::vector<LSPLocation>
LanguageServer::declaration(DeclarationParams &params) {
  auto path = extractPathFromUrl(params.textDocument.uri);
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->jumpTo(path, params.position);
    }
  }
  return {};
}

std::vector<LSPLocation> LanguageServer::definition(DefinitionParams &params) {
  auto path = extractPathFromUrl(params.textDocument.uri);
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->jumpTo(path, params.position);
    }
  }
  return {};
}

std::vector<FoldingRange>
LanguageServer::foldingRanges(FoldingRangeParams &params) {
  auto path = extractPathFromUrl(params.textDocument.uri);
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->foldingRanges(path);
    }
  }
  return {};
}

std::optional<Hover> LanguageServer::hover(HoverParams &params) {
  auto path = extractPathFromUrl(params.textDocument.uri);
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->hover(path, params.position);
    }
  }
  return std::nullopt;
}

void LanguageServer::onDidSaveTextDocument(DidSaveTextDocumentParams &params) {}

void LanguageServer::onDidCloseTextDocument(
    DidCloseTextDocumentParams &params) {
  auto path = extractPathFromUrl(params.textDocument.uri);
  if (this->cachedContents.contains(path)) {
    auto iter = this->cachedContents.find(path);
    this->cachedContents.erase(iter);
  }
  for (auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      workspace->dropCache(path);
      return;
    }
  }
}

void LanguageServer::publishDiagnostics(
    std::map<std::filesystem::path, std::vector<LSPDiagnostic>> newDiags) {
  for (const auto &pair : newDiags) {
    auto asURI = pathToUrl(pair.first);
    auto clearingParams = PublishDiagnosticsParams(asURI, {});
    this->server->notification("textDocument/publishDiagnostics",
                               clearingParams.toJson());
    auto newParams = PublishDiagnosticsParams(asURI, pair.second);
    this->server->notification("textDocument/publishDiagnostics",
                               newParams.toJson());
    LOG.info(std::format("Publishing {} diagnostics for {}", pair.second.size(),
                         pair.first.generic_string()));
  }
}
