#include "langserver.hpp"

#include "langserverutils.hpp"
#include "libpkgconf/iter.h"
#include "log.hpp"
#include "lsptypes.hpp"
#include "polyfill.hpp"
#include "utils.hpp"
#include "workspace.hpp"

#include <cassert>
#include <cerrno>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <exception>
#include <filesystem>
#include <format>
#include <fstream>
#include <functional>
#include <future>
#include <libpkgconf/libpkgconf.h>
#include <map>
#include <memory>
#include <optional>
#include <ostream>
#include <stdexcept>
#include <string>
#ifdef HAS_INOTIFY
#include <poll.h>
#include <sys/inotify.h>
#endif
#include <vector>
extern "C" {
// Dirty hack
#define ast muon_ast
#define fmt muon_fmt
#include <lang/fmt.h>
#include <log.h>
#include <platform/filesystem.h>
#include <platform/init.h>
#undef ast
#undef fmt
}

const static Logger LOG("LanguageServer"); // NOLINT

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

void LanguageServer::initPkgNames() {
  this->pkgNames.clear();
  auto soutOpt = captureProcessOutput("pkg-config", {"--list-all"});
  if (soutOpt.has_value()) {
    auto sout = soutOpt.value();
    std::string pkgName;
    std::string pkgDescription;
    auto state = 0;
    for (const auto chr : sout) {
      if (chr == '\n') {
        LOG.info("Found package: " + pkgName + "(" + pkgDescription + ")");
        pkgNames.insert(pkgName);
        pkgName = "";
        pkgDescription = "";
        state = 0;
        continue;
      }
      if (state == 0) {
        if (chr == ' ') {
          state = 1;
        } else {
          pkgName.push_back(chr);
        }
        continue;
      }
      if (state == 1) {
        if (chr != ' ') {
          pkgDescription.push_back(chr);
          state = 2;
        }
        continue;
      }
      if (state == 2) {
        if (chr != '\r') {
          pkgDescription.push_back(chr);
        }
      }
    }
    return;
  }
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
  for (const auto &path : this->options.pkgConfigDirectories) {
    // LEAK: It's better to leak memory than have e.g. double frees
    pkgconf_path_add(strdup(path.c_str()), &pkgClient.dir_list, false);
  }
  pkgconf_scan_all(
      &pkgClient, this, [](const pkgconf_pkg_t *entry, auto *data) {
        if ((entry->flags & PKGCONF_PKG_PROPF_UNINSTALLED) != 0U) {
          return false;
        }
        std::string const pkgName{entry->id};

        if (((LanguageServer *)data)->pkgNames.insert(pkgName).second) {
          LOG.info("Found package: " + pkgName);
        }
        return false;
      });
  pkgconf_cross_personality_deinit(personality);
  pkgconf_client_deinit(&pkgClient);
}

void LanguageServer::onDidChangeConfiguration(
    DidChangeConfigurationParams &params) {
  this->options.update(params.settings);
  this->initPkgNames();
  for (const auto &workspace : this->workspaces) {
    const auto &oldDiags = workspace->clearDiagnostics();
    workspace->options = this->options;
    this->publishDiagnostics(oldDiags);
    const auto &diags = workspace->parse(this->ns);
    this->publishDiagnostics(diags);
  }
}

InitializeResult LanguageServer::initialize(InitializeParams &params) {
#ifndef _WIN32
  platform_init();
#endif
  log_init();

  this->options.update(params.initializationOptions);
  this->initPkgNames();

  for (const auto &wspf : params.workspaceFolders) {
    auto workspace = std::make_shared<Workspace>(wspf, this->options);
    const auto &diags = workspace->parse(this->ns);
    this->diagnosticsFromInitialisation.emplace_back(diags);
    this->workspaces.push_back(workspace);
  }
#ifdef HAS_INOTIFY
  this->setupInotify();
#endif
  return InitializeResult{
      ServerCapabilities(
          TextDocumentSyncOptions(true, TextDocumentSyncKind::FULL), true, true,
          true, true, true, true, true, true, true, true,
          CompletionOptions(false, {".", "_", ")"}),
          SemanticTokensOptions(
              true, SemanticTokensLegend({"substitute", "substitute_bounds",
                                          "variable", "function", "method",
                                          "keyword", "string", "number"},
                                         {"readonly", "defaultLibrary"}))),
      ServerInfo("c++-mesonlsp", VERSION)};
}

#ifdef HAS_INOTIFY
void LanguageServer::setupInotify() {
  this->smph.acquire();
  this->inotifyFd = inotify_init1(IN_NONBLOCK);
  if (this->inotifyFd == -1) {
    LOG.error(std::format("Failed inotify_init1: {}", errno2string()));
    this->smph.release();
    return;
  }
  std::map<std::filesystem::path, int> fds;
  for (const auto &subTree : this->workspaces) {
    const auto subprojectsDir = subTree->root / "subprojects";
    if (!std::filesystem::exists(subprojectsDir)) {
      continue;
    }
    const auto watchFd = inotify_add_watch(
        this->inotifyFd, subprojectsDir.generic_string().c_str(),
        IN_OPEN | IN_CLOSE);
    if (watchFd == -1) {
      LOG.error(std::format("Failed inotify_add_watch: {}", errno2string()));
      continue;
    }
    LOG.info(std::format("Watching {} with {}", subprojectsDir.generic_string(),
                         watchFd));
    fds[subTree->root] = watchFd;
  }
  this->inotifyFuture =
      std::async(std::launch::async, &LanguageServer::watch, this, fds);
  this->smph.release();
}

void LanguageServer::watch(
    std::map<std::filesystem::path, int> /*NOLINT*/ fds) {
  int nFds = 1;
  struct pollfd pollFd; // NOLINT
  pollFd.fd = this->inotifyFd;
  pollFd.events = POLLIN;
  while (true) {
    auto pollNum = poll(&pollFd, nFds, 1000);
    if (this->inotifyFd == -1) {
      return;
    }
    if (pollNum == -1) {
      if (errno == EINTR) {
        continue;
      }
      LOG.error(std::format("Failed to poll(): {}", errno2string()));
      return;
    }
    if (pollNum == 0) {
      continue;
    }
    if ((pollFd.revents & POLLIN) == 0) {
      continue;
    }
    char /*NOLINT*/ buf[4096]
        __attribute__((aligned(__alignof__(struct inotify_event))));
    const struct inotify_event *event = nullptr;
    while (true) {
      auto len = read(this->inotifyFd, buf, sizeof(buf));
      if (len == -1 && errno != EAGAIN) {
        LOG.error(std::format("Failed to read(): {}", errno2string()));
        break;
      }
      if (len <= 0) {
        break;
      }
      for (char *ptr = buf; ptr < buf + len;
           ptr += sizeof(struct inotify_event) + event->len) {
        event = (const struct inotify_event *)ptr;
        if ((event->mask & IN_ISDIR) != 0U) {
          continue;
        }
        if ((event->mask & IN_OPEN) != 0U) {
          continue;
        }
        if ((event->mask & IN_CLOSE_WRITE) == 0U) {
          continue;
        }
        LOG.info(std::format("Mask: 0x{:x}", event->mask));
        for (const auto &[path, fd] : fds) {
          if (fd != event->wd) {
            continue;
          }
          const auto *name = event->len != 0U ? event->name : "???";
          LOG.info(std::format("Found modification at: {}/subprojects/{}",
                               path.generic_string(), name));
          const std::string asString = name;
          if (asString.ends_with(".wrap")) {
            this->fullReparse(path);
          }
        }
      }
    }
  }
}
#else
#warning "No inotify support on this platform. (Contributions welcome)"
#endif

void LanguageServer::fullReparse(const std::filesystem::path &path) {
  this->smph.acquire();
  for (const auto &workspace : this->workspaces) {
    if (path != workspace->root) {
      continue;
    }
    const auto oldDiags = workspace->clearDiagnostics();
    const auto &diags = workspace->fullReparse(this->ns);
    this->publishDiagnostics(oldDiags);
    this->publishDiagnostics(diags);
    break;
  }
  this->smph.release();
}

void LanguageServer::shutdown() {
#ifdef HAS_INOTIFY
  this->inotifyFd = -1;
#endif
}

void LanguageServer::onInitialized(InitializedParams & /*params*/) {
  for (const auto &map : this->diagnosticsFromInitialisation) {
    this->publishDiagnostics(map);
  }
  this->diagnosticsFromInitialisation.clear();
}

void LanguageServer::onExit() {
#ifdef __APPLE__
  _Exit(0);
#elif !defined(_WIN32)
  _exit(0);
#else
  exit(0);
#endif
}

void LanguageServer::onDidOpenTextDocument(
    DidOpenTextDocumentParams & /*params*/) {}

void LanguageServer::onDidChangeTextDocument(
    DidChangeTextDocumentParams &params) {
  this->smph.acquire();
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  this->cachedContents[path] = params.contentChanges[0].text;
  for (const auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      LOG.info(std::format("Patching file {} for workspace {}",
                           path.generic_string(), workspace->name));
      workspace->patchFile<std::function<void(
          std::map<std::filesystem::path, std::vector<LSPDiagnostic>>)>>(
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
  for (const auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->inlayHints(path);
    }
  }
  return {};
}

std::vector<SymbolInformation>
LanguageServer::documentSymbols(DocumentSymbolParams &params) {
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  for (const auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->documentSymbols(path);
    }
  }
  return {};
}

TextEdit LanguageServer::formatting(DocumentFormattingParams &params) {
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  const auto toFormat = this->cachedContents.contains(path)
                            ? this->cachedContents[path]
                            : readFile(path);
  std::filesystem::path configFile;
  for (const auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      if (auto file = workspace->muonConfigFile(path)) {
        configFile = file.value();
      }
    }
  }
  if (configFile.empty() && this->options.defaultFormattingConfig.has_value()) {
    configFile = this->options.defaultFormattingConfig.value();
  }
  if (configFile.empty()) {
    configFile = writeMuonConfigFile(params.options);
  }
#ifndef _WIN32
#ifndef _WIN32
  const auto *labelPath = path.c_str();
#else
  const wchar_t *labelPathW = path.c_str();
  char *labelPath = (char *)calloc(path.generic_string().size() * 2, 1);
  // Should be use wcstombs_s?
  wcstombs(labelPath, labelPathW, path.generic_string().size() * 2);
#endif
  struct source src = {.label = labelPath,
                       .src = strdup(toFormat.data()),
                       .len = toFormat.size(),
                       .reopen_type = source_reopen_type_none};
  char *formattedStr;
  size_t formattedSize;
  auto *output = open_memstream(&formattedStr, &formattedSize);
  auto fmtRet = muon_fmt(&src, output, configFile.c_str(), false, true);
  if (!fmtRet) {
    (void)fclose(output);
    free((void *)src.src);
    free(formattedStr);
#ifdef _WIN32
    free(labelPath);
#endif
    LOG.error("Failed to format");
    throw std::runtime_error("Failed to format");
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
#ifdef _WIN32
  free(labelPath);
#endif
  return edit;
#else
#warning "Please contribute (open_memstream has to be replaced...) :)"
  throw std::runtime_error("Please contribute formatting support for windows "
                           "(open_memstream has to be replaced...) :)");
#endif
}

std::vector<uint64_t>
LanguageServer::semanticTokens(SemanticTokensParams &params) {
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  for (const auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->semanticTokens(path);
    }
  }
  return {};
}

std::vector<DocumentHighlight>
LanguageServer::highlight(DocumentHighlightParams &params) {
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  for (const auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->highlight(path, params.position);
    }
  }
  return {};
}

std::optional<WorkspaceEdit> LanguageServer::rename(RenameParams &params) {
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  for (const auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->rename(path, params);
    }
  }
  return std::nullopt;
}

std::vector<LSPLocation>
LanguageServer::declaration(DeclarationParams &params) {
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  for (const auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->jumpTo(path, params.position);
    }
  }
  return {};
}

std::vector<LSPLocation> LanguageServer::definition(DefinitionParams &params) {
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  for (const auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->jumpTo(path, params.position);
    }
  }
  return {};
}

std::vector<CodeAction> LanguageServer::codeAction(CodeActionParams &params) {
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  for (const auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->codeAction(path, params.range);
    }
  }
  return {};
}

std::vector<FoldingRange>
LanguageServer::foldingRanges(FoldingRangeParams &params) {
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  for (const auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->foldingRanges(path);
    }
  }
  return {};
}

std::optional<Hover> LanguageServer::hover(HoverParams &params) {
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  for (const auto &workspace : this->workspaces) {
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
  for (const auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      workspace->dropCache(path);
      return;
    }
  }
}

std::vector<CompletionItem>
LanguageServer::completion(CompletionParams &params) {
  const auto &path = extractPathFromUrl(params.textDocument.uri);
  for (const auto &workspace : this->workspaces) {
    if (workspace->owns(path)) {
      return workspace->completion(path, params.position, this->pkgNames);
    }
  }
  return {};
}

void LanguageServer::publishDiagnostics(
    const std::map<std::filesystem::path, std::vector<LSPDiagnostic>>
        &newDiags) {
  for (const auto &[filePath, diags] : newDiags) {
    const auto &asURI = pathToUrl(filePath);
    const auto &clearingParams = PublishDiagnosticsParams(asURI, {});
    this->server->notification("textDocument/publishDiagnostics",
                               clearingParams.toJson());
    const auto &newParams = PublishDiagnosticsParams(asURI, diags);
    this->server->notification("textDocument/publishDiagnostics",
                               newParams.toJson());
    LOG.info(std::format("Publishing {} diagnostics for {}", diags.size(),
                         filePath.generic_string()));
  }
}
