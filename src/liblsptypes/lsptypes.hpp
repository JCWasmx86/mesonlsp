#pragma once
#include <cassert>
#include <cstdint>
#include <map>
#include <nlohmann/json.hpp>
#include <optional>
#include <string>
#include <utility>
#include <vector>

class BaseObject {
public:
  virtual ~BaseObject() = default;
};

class ClientInfo : public BaseObject {
public:
  std::string name;
  std::optional<std::string> version;

  explicit ClientInfo(nlohmann::json data) {
    this->name = data["name"];
    if (data.contains("version")) {
      this->version = data["version"];
    }
  }
};

class WorkspaceFolder : public BaseObject {
public:
  std::string uri;
  std::string name;

  explicit WorkspaceFolder(nlohmann::json &jsonObj) {
    this->uri = jsonObj["uri"];
    this->name = jsonObj["name"];
  }
};

class ClientCapabilities : public BaseObject {};

enum class TextDocumentSyncKind { NONE = 0, FULL = 1, INCREMENTAL = 2 };

class SemanticTokensLegend : public BaseObject {
public:
  std::vector<std::string> tokenTypes;
  std::vector<std::string> tokenModifiers;

  SemanticTokensLegend(std::vector<std::string> tokenTypes,
                       std::vector<std::string> tokenModifiers)
      : tokenTypes(std::move(tokenTypes)),
        tokenModifiers(std::move(tokenModifiers)) {}

  [[nodiscard]] nlohmann::json toJson() const {
    return {{"tokenTypes", tokenTypes}, {"tokenModifiers", tokenModifiers}};
  }
};

class CompletionOptions : public BaseObject {
public:
  std::vector<std::string> triggerCharacters;
  bool resolveProvider;

  CompletionOptions(bool resolveProvider,
                    std::vector<std::string> triggerCharacters)
      : triggerCharacters(std::move(triggerCharacters)),
        resolveProvider(resolveProvider) {}

  [[nodiscard]] nlohmann::json toJson() const {
    return {{"triggerCharacters", triggerCharacters},
            {"resolveProvider", resolveProvider}};
  }
};

class SemanticTokensOptions : public BaseObject {
public:
  bool full;
  SemanticTokensLegend legend;

  SemanticTokensOptions(bool full, SemanticTokensLegend legend)
      : full(full), legend(std::move(legend)) {}

  [[nodiscard]] nlohmann::json toJson() const {
    return {{"full", full}, {"legend", legend.toJson()}};
  }
};

class TextDocumentSyncOptions : public BaseObject {
public:
  bool openClose;
  TextDocumentSyncKind change;

  TextDocumentSyncOptions(bool openClose, TextDocumentSyncKind change)
      : openClose(openClose), change(change) {}

  [[nodiscard]] nlohmann::json toJson() const {
    return {{"openClose", openClose}, {"change", change}};
  }
};

class ServerCapabilities : public BaseObject {
public:
  TextDocumentSyncOptions textDocumentSync;
  bool hoverProvider;
  bool declarationProvider;
  bool definitionProvider;
  bool documentHighlightProvider;
  bool documentSymbolProvider;
  bool codeActionProvider;
  bool documentFormattingProvider;
  bool renameProvider;
  bool foldingRangeProvider;
  bool inlayHintProvider;
  CompletionOptions completionProvider;
  SemanticTokensOptions semanticTokensProvider;

  // This is stupid
  ServerCapabilities(TextDocumentSyncOptions textDocumentSync,
                     bool hoverProvider, bool declarationProvider,
                     bool definitionProvider, bool documentHighlightProvider,
                     bool documentSymbolProvider, bool codeActionProvider,
                     bool documentFormattingProvider, bool renameProvider,
                     bool foldingRangeProvider, bool inlayHintProvider,
                     CompletionOptions completionProvider,
                     SemanticTokensOptions semanticTokensProvider)
      : textDocumentSync(std::move(textDocumentSync)),
        hoverProvider(hoverProvider), declarationProvider(declarationProvider),
        definitionProvider(definitionProvider),
        documentHighlightProvider(documentHighlightProvider),
        documentSymbolProvider(documentSymbolProvider),
        codeActionProvider(codeActionProvider),
        documentFormattingProvider(documentFormattingProvider),
        renameProvider(renameProvider),
        foldingRangeProvider(foldingRangeProvider),
        inlayHintProvider(inlayHintProvider),
        completionProvider(std::move(completionProvider)),
        semanticTokensProvider(std::move(semanticTokensProvider)) {}

  [[nodiscard]] nlohmann::json toJson() const {
    return {{"textDocumentSync", this->textDocumentSync.toJson()},
            {"hoverProvider", hoverProvider},
            {"definitionProvider", definitionProvider},
            {"declarationProvider", declarationProvider},
            {"documentHighlightProvider", documentHighlightProvider},
            {"documentSymbolProvider", documentSymbolProvider},
            {"codeActionProvider", codeActionProvider},
            {"documentFormattingProvider", documentFormattingProvider},
            {"renameProvider", renameProvider},
            {"foldingRangeProvider", foldingRangeProvider},
            {"inlayHintProvider", inlayHintProvider},
            {"completionProvider", completionProvider.toJson()},
            {"semanticTokensProvider", semanticTokensProvider.toJson()}};
  }
};

class InitializeParams : public BaseObject {
public:
  std::optional<ClientInfo> clientInfo;
  std::vector<WorkspaceFolder> workspaceFolders;
  std::optional<nlohmann::json> initializationOptions;
  ClientCapabilities capabilities;

  explicit InitializeParams(nlohmann::json &jsonObj) {
    if (jsonObj.contains("clientInfo")) {
      this->clientInfo = ClientInfo(jsonObj["clientInfo"]);
    }
    if (jsonObj.contains("initializationOptions")) {
      this->initializationOptions = jsonObj["initializationOptions"];
    }
    assert(jsonObj.contains("workspaceFolders"));
    for (auto wsFolder : jsonObj["workspaceFolders"]) {
      this->workspaceFolders.emplace_back(wsFolder);
    }
  }
};

class ServerInfo : public BaseObject {
public:
  std::string name;
  std::string version;

  ServerInfo(std::string name, std::string version)
      : name(std::move(name)), version(std::move(version)) {}

  [[nodiscard]] nlohmann::json toJson() const {
    return {{"name", name}, {"version", version}};
  }
};

class InitializeResult : public BaseObject {
public:
  ServerCapabilities capabilities;
  std::optional<ServerInfo> serverInfo;

  explicit InitializeResult(ServerCapabilities capabilities,
                            std::optional<ServerInfo> serverInfo = std::nullopt)
      : capabilities(std::move(capabilities)),
        serverInfo(std::move(serverInfo)) {}

  [[nodiscard]] nlohmann::json toJson() const {
    nlohmann::json ret;
    ret["capabilities"] = capabilities.toJson();
    if (serverInfo.has_value()) {
      ret["serverInfo"] = serverInfo->toJson();
    }
    return ret;
  }
};

enum class DiagnosticSeverity {
  LSP_ERROR = 1,
  LSP_WARNING = 2,
};

enum class DiagnosticTag {
  LSP_UNNECESSARY = 1,
  LSP_DEPRECATED = 2,
};

class LSPPosition : public BaseObject {
public:
  uint64_t line;
  uint64_t character;

  LSPPosition(uint64_t line, uint64_t character)
      : line(line), character(character) {}

  explicit LSPPosition(nlohmann::json &jsonObj) {
    this->line = jsonObj["line"];
    this->character = jsonObj["character"];
  }

  [[nodiscard]] nlohmann::json toJson() const {
    return {{"line", line}, {"character", character}};
  }

  bool operator<(const LSPPosition &right) const {
    if (this->line < right.line) {
      return true;
    }
    if (this->line > right.line) {
      return false;
    }
    return this->character < right.character;
  }
};

class LSPRange : public BaseObject {
public:
  LSPPosition start;
  LSPPosition end;

  LSPRange(LSPPosition start, LSPPosition end)
      : start(std::move(start)), end(std::move(end)) {}

  explicit LSPRange(nlohmann::json &jsonObj)
      : start(jsonObj["start"]), end(jsonObj["end"]) {}

  [[nodiscard]] nlohmann::json toJson() const {
    return {{"start", start.toJson()}, {"end", end.toJson()}};
  }

  [[nodiscard]] bool contains(const LSPPosition &position) const {
    if (position.line > this->start.line && position.line < this->end.line) {
      return true;
    }
    if (position.line == this->start.line && position.line == this->end.line) {
      return position.character >= this->start.character &&
             position.character <= this->end.character;
    }
    if (position.line == this->start.line) {
      return position.character >= this->start.character;
    }
    if (position.line == this->end.line) {
      return position.character <= this->end.character;
    }
    return false;
  }

  bool operator<(const LSPRange &right) const {
    return this->start < right.start;
  }
};

class LSPDiagnostic : public BaseObject {
public:
  LSPRange range;
  DiagnosticSeverity severity;
  std::string message;
  std::vector<DiagnosticTag> tags;

  LSPDiagnostic(LSPRange range, DiagnosticSeverity severity,
                std::string message, std::vector<DiagnosticTag> tags)
      : range(std::move(range)), severity(severity),
        message(std::move(message)), tags(std::move(tags)) {}

  [[nodiscard]] nlohmann::json toJson() const {
    return {{"range", range.toJson()},
            {"severity", severity},
            {"message", message},
            {"tags", tags}};
  }

  bool operator<(const LSPDiagnostic &right) const {
    return this->range < right.range;
  }
};

class PublishDiagnosticsParams : public BaseObject {
public:
  std::string uri;
  std::vector<LSPDiagnostic> diagnostics;

  PublishDiagnosticsParams(std::string uri,
                           std::vector<LSPDiagnostic> diagnostics)
      : uri(std::move(uri)), diagnostics(std::move(diagnostics)) {}

  [[nodiscard]] nlohmann::json toJson() const {
    std::vector<nlohmann::json> objs;
    objs.reserve(this->diagnostics.size());
    for (const auto &diag : this->diagnostics) {
      objs.push_back(diag.toJson());
    }
    return {{"uri", uri}, {"diagnostics", objs}};
  }
};

class InitializedParams : public BaseObject {
public:
  InitializedParams() = default;
};

class TextDocumentItem : public BaseObject {
public:
  std::string uri;
  std::string text;

  explicit TextDocumentItem(nlohmann::json &jsonObj) {
    this->uri = jsonObj["uri"];
    this->text = jsonObj["text"];
  }
};

class DidOpenTextDocumentParams : public BaseObject {
public:
  TextDocumentItem textDocument;

  explicit DidOpenTextDocumentParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]) {}
};

class TextDocumentIdentifier : public BaseObject {
public:
  std::string uri;

  explicit TextDocumentIdentifier(nlohmann::json &jsonObj)
      : uri(jsonObj["uri"]) {}
};

class TextDocumentContentChangeEvent : public BaseObject {
public:
  std::string text;

  explicit TextDocumentContentChangeEvent(nlohmann::json &jsonObj)
      : text(jsonObj["text"]) {}
};

class DidChangeTextDocumentParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;
  std::vector<TextDocumentContentChangeEvent> contentChanges;

  explicit DidChangeTextDocumentParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]) {
    for (auto &change : jsonObj["contentChanges"]) {
      contentChanges.emplace_back(change);
    }
  }
};

class DidSaveTextDocumentParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;
  std::string text;

  explicit DidSaveTextDocumentParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]), text(jsonObj["text"]) {}
};

class DidCloseTextDocumentParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;

  explicit DidCloseTextDocumentParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]) {}
};

class InlayHintParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;
  LSPRange range;

  explicit InlayHintParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]), range(jsonObj["range"]) {}
};

class InlayHint : public BaseObject {
public:
  LSPPosition position;
  std::string label;

  InlayHint(LSPPosition position, std::string label)
      : position(std::move(position)), label(std::move(label)) {}

  [[nodiscard]] nlohmann::json toJson() const {
    return {{"position", position.toJson()}, {"label", this->label}};
  }
};

class FoldingRangeParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;

  explicit FoldingRangeParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]) {}
};

class FoldingRange : public BaseObject {
public:
  uint64_t startLine;
  uint64_t endLine;

  FoldingRange(uint64_t startLine, uint64_t endLine)
      : startLine(startLine), endLine(endLine) {}

  [[nodiscard]] nlohmann::json toJson() const {
    return {{"startLine", startLine}, {"endLine", endLine}};
  }
};

class SemanticTokensParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;

  explicit SemanticTokensParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]) {}
};

class FormattingOptions : public BaseObject {
public:
  uint8_t tabSize;
  bool insertSpaces;

  explicit FormattingOptions(nlohmann::json &jsonObj) {
    this->tabSize = jsonObj["tabSize"];
    this->insertSpaces = jsonObj["insertSpaces"];
  }
};

class DocumentFormattingParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;
  FormattingOptions options;

  explicit DocumentFormattingParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]), options(jsonObj["options"]) {}
};

class TextEdit : public BaseObject {
public:
  LSPRange range;
  std::string newText;

  TextEdit(LSPRange range, std::string newText)
      : range(std::move(range)), newText(std::move(newText)) {}

  [[nodiscard]] nlohmann::json toJson() const {
    return {{"range", range.toJson()}, {"newText", newText}};
  }
};

class DocumentSymbolParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;

  explicit DocumentSymbolParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]) {}
};

enum class SymbolKind {
  VARIABLE_KIND = 13,
  STRING_KIND = 15,
  NUMBER_KIND = 16,
  BOOLEAN_KIND = 17,
  LIST_KIND = 18,
  OBJECT_KIND = 19,
};

class LSPLocation {
public:
  std::string uri;
  LSPRange range;

  LSPLocation(std::string uri, LSPRange range)
      : uri(std::move(uri)), range(std::move(range)) {}

  [[nodiscard]] nlohmann::json toJson() const {
    return {{"uri", uri}, {"range", range.toJson()}};
  }
};

class SymbolInformation : public BaseObject {
public:
  std::string name;
  SymbolKind kind;
  LSPLocation location;

  SymbolInformation(std::string name, SymbolKind kind, LSPLocation location)
      : name(std::move(name)), kind(kind), location(std::move(location)) {}

  [[nodiscard]] nlohmann::json toJson() const {
    return {{"name", name}, {"kind", kind}, {"location", location.toJson()}};
  }
};

class HoverParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;
  LSPPosition position;

  explicit HoverParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]), position(jsonObj["position"]) {}
};

class MarkupContent : public BaseObject {
public:
  std::string value;

  explicit MarkupContent(std::string value) : value(std::move(value)) {}

  [[nodiscard]] nlohmann::json toJson() const {
    return {{"value", value}, {"kind", "markdown"}};
  }
};

class Hover : public BaseObject {
public:
  MarkupContent contents;

  explicit Hover(MarkupContent contents) : contents(std::move(contents)) {}

  [[nodiscard]] nlohmann::json toJson() const {
    return {{"contents", contents.toJson()}};
  }
};

class DocumentHighlightParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;
  LSPPosition position;

  explicit DocumentHighlightParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]), position(jsonObj["position"]) {}
};

enum class DocumentHighlightKind {
  READ_KIND = 1,
  WRITE_KIND = 2,
};

class DocumentHighlight : public BaseObject {
public:
  LSPRange range;
  DocumentHighlightKind kind;

  DocumentHighlight(LSPRange range, DocumentHighlightKind kind)
      : range(std::move(range)), kind(kind) {}

  [[nodiscard]] nlohmann::json toJson() const {
    return {{"range", range.toJson()}, {"kind", kind}};
  }
};

class RenameParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;
  LSPPosition position;
  std::string newName;

  explicit RenameParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]), position(jsonObj["position"]),
        newName(jsonObj["newName"]) {}
};

class WorkspaceEdit : public BaseObject {
public:
  std::map<std::string, std::vector<TextEdit>> changes;

  [[nodiscard]] nlohmann::json toJson() const {
    nlohmann::json ret;
    for (const auto &[path, edits] : changes) {
      std::vector<nlohmann::json> vec;
      vec.reserve(edits.size());
      for (const auto &edit : edits) {
        vec.push_back(edit.toJson());
      }
      ret[path] = vec;
    }
    return {{"changes", ret}};
  }
};

class DeclarationParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;
  LSPPosition position;

  explicit DeclarationParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]), position(jsonObj["position"]) {}
};

class DefinitionParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;
  LSPPosition position;

  explicit DefinitionParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]), position(jsonObj["position"]) {}
};

class CodeActionParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;
  LSPRange range;

  // Ignore the context :p

  explicit CodeActionParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]), range(jsonObj["range"]) {}
};

class CodeAction : public BaseObject {
public:
  std::string title;
  WorkspaceEdit edit;

  CodeAction(std::string title, WorkspaceEdit edit)
      : title(std::move(title)), edit(std::move(edit)) {}

  [[nodiscard]] nlohmann::json toJson() const {
    return {{"title", title}, {"edit", edit.toJson()}};
  }
};

class CompletionParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;
  LSPPosition position;

  explicit CompletionParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]), position(jsonObj["position"]) {}
};

enum class CompletionItemKind {
  METHOD = 2,
  FUNCTION = 3,
  VARIABLE = 6,
  KEYWORD = 14,
  CIK_FILE = 17,
  CONSTANT = 21,
};

class CompletionItem : public BaseObject {
public:
  std::string label;
  CompletionItemKind kind;
  TextEdit textEdit;

  CompletionItem(std::string label, CompletionItemKind kind, TextEdit textEdit)
      : label(std::move(label)), kind(kind), textEdit(std::move(textEdit)) {}

  [[nodiscard]] nlohmann::json toJson() const {
    return {
        {"label", label},
        {"kind", kind},
        {"textEdit", textEdit.toJson()},
        {"insertTextFormat", 2},
    };
  }
};

class DidChangeConfigurationParams : public BaseObject {
public:
  nlohmann::json settings;

  explicit DidChangeConfigurationParams(nlohmann::json &jsonObj)
      : settings(jsonObj["settings"]) {}
};
