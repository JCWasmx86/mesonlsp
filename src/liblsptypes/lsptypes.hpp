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

  ClientInfo(nlohmann::json data) {
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

  WorkspaceFolder(nlohmann::json &jsonObj) {
    this->uri = jsonObj["uri"];
    this->name = jsonObj["name"];
  }
};

class ClientCapabilities : public BaseObject {};

enum TextDocumentSyncKind { None = 0, Full = 1, Incremental = 2 };

class SemanticTokensLegend : public BaseObject {
public:
  std::vector<std::string> tokenTypes;
  std::vector<std::string> tokenModifiers;

  SemanticTokensLegend(std::vector<std::string> tokenTypes,
                       std::vector<std::string> tokenModifiers)
      : tokenTypes(std::move(tokenTypes)),
        tokenModifiers(std::move(tokenModifiers)) {}

  nlohmann::json toJson() const {
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

  nlohmann::json toJson() const {
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

  nlohmann::json toJson() const {
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

  nlohmann::json toJson() const {
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

  InitializeParams(nlohmann::json &jsonObj) {
    if (jsonObj.contains("clientInfo")) {
      this->clientInfo = ClientInfo(jsonObj["clientInfo"]);
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

  InitializeResult(ServerCapabilities capabilities,
                   std::optional<ServerInfo> serverInfo = std::nullopt)
      : capabilities(std::move(capabilities)),
        serverInfo(std::move(serverInfo)) {}

  nlohmann::json toJson() const {
    nlohmann::json ret;
    ret["capabilities"] = capabilities.toJson();
    if (serverInfo.has_value()) {
      ret["serverInfo"] = serverInfo->toJson();
    }
    return ret;
  }
};

enum DiagnosticSeverity {
  LSPError = 1,
  LSPWarning = 2,
};

enum DiagnosticTag {
  LSPUnnecessary = 1,
  LSPDeprecated = 2,
};

class LSPPosition : public BaseObject {
public:
  uint64_t line;
  uint64_t character;

  LSPPosition(uint64_t line, uint64_t character)
      : line(line), character(character) {}

  LSPPosition(nlohmann::json &jsonObj) {
    this->line = jsonObj["line"];
    this->character = jsonObj["character"];
  }

  [[nodiscard]] nlohmann::json toJson() const {
    return {{"line", line}, {"character", character}};
  }
};

class LSPRange : public BaseObject {
public:
  LSPPosition start;
  LSPPosition end;

  LSPRange(LSPPosition start, LSPPosition end)
      : start(std::move(start)), end(std::move(end)) {}

  LSPRange(nlohmann::json &jsonObj)
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
};

class PublishDiagnosticsParams : public BaseObject {
public:
  std::string uri;
  std::vector<LSPDiagnostic> diagnostics;

  PublishDiagnosticsParams(std::string uri,
                           std::vector<LSPDiagnostic> diagnostics)
      : uri(std::move(uri)), diagnostics(std::move(diagnostics)) {}

  nlohmann::json toJson() const {
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

  TextDocumentItem(nlohmann::json &jsonObj) {
    this->uri = jsonObj["uri"];
    this->text = jsonObj["text"];
  }
};

class DidOpenTextDocumentParams : public BaseObject {
public:
  TextDocumentItem textDocument;

  DidOpenTextDocumentParams(nlohmann::json &jsonObj) : textDocument(jsonObj) {}
};

class TextDocumentIdentifier : public BaseObject {
public:
  std::string uri;

  TextDocumentIdentifier(nlohmann::json &jsonObj) : uri(jsonObj["uri"]) {}
};

class TextDocumentContentChangeEvent : public BaseObject {
public:
  std::string text;

  TextDocumentContentChangeEvent(nlohmann::json &jsonObj)
      : text(jsonObj["text"]) {}
};

class DidChangeTextDocumentParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;
  std::vector<TextDocumentContentChangeEvent> contentChanges;

  DidChangeTextDocumentParams(nlohmann::json &jsonObj)
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

  DidSaveTextDocumentParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]), text(jsonObj["text"]) {}
};

class DidCloseTextDocumentParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;

  DidCloseTextDocumentParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]) {}
};

class InlayHintParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;
  LSPRange range;

  InlayHintParams(nlohmann::json &jsonObj)
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

  FoldingRangeParams(nlohmann::json &jsonObj)
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

  SemanticTokensParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]) {}
};

class FormattingOptions : public BaseObject {
public:
  uint8_t tabSize;
  bool insertSpaces;

  FormattingOptions(nlohmann::json &jsonObj) {
    this->tabSize = jsonObj["tabSize"];
    this->insertSpaces = jsonObj["insertSpaces"];
  }
};

class DocumentFormattingParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;
  FormattingOptions options;

  DocumentFormattingParams(nlohmann::json &jsonObj)
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

  DocumentSymbolParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]) {}
};

enum SymbolKind {
  VariableKind = 13,
  StringKind = 15,
  NumberKind = 16,
  BooleanKind = 17,
  ListKind = 18,
  ObjectKind = 19,
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

  HoverParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]), position(jsonObj["position"]) {}
};

class MarkupContent : public BaseObject {
public:
  std::string value;

  MarkupContent(std::string value) : value(std::move(value)) {}

  [[nodiscard]] nlohmann::json toJson() const {
    return {{"value", value}, {"kind", "markdown"}};
  }
};

class Hover : public BaseObject {
public:
  MarkupContent contents;

  Hover(MarkupContent contents) : contents(std::move(contents)) {}

  [[nodiscard]] nlohmann::json toJson() const {
    return {{"contents", contents.toJson()}};
  }
};

class DocumentHighlightParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;
  LSPPosition position;

  DocumentHighlightParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]), position(jsonObj["position"]) {}
};

enum DocumentHighlightKind {
  ReadKind = 1,
  WriteKind = 2,
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

  RenameParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]), position(jsonObj["position"]),
        newName(jsonObj["newName"]) {}
};

class WorkspaceEdit : public BaseObject {
public:
  std::map<std::string, std::vector<TextEdit>> changes;

  nlohmann::json toJson() const {
    nlohmann::json ret;
    for (const auto &pair : changes) {
      std::vector<nlohmann::json> vec;
      vec.reserve(pair.second.size());
      for (const auto &edit : pair.second) {
        vec.push_back(edit.toJson());
      }
      ret[pair.first] = vec;
    }
    return {{"changes", ret}};
  }
};

class DeclarationParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;
  LSPPosition position;

  DeclarationParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]), position(jsonObj["position"]) {}
};

class DefinitionParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;
  LSPPosition position;

  DefinitionParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]), position(jsonObj["position"]) {}
};

class CodeActionParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;
  LSPRange range;

  // Ignore the context :p

  CodeActionParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]), range(jsonObj["range"]) {}
};

class CodeAction : public BaseObject {
public:
  std::string title;
  WorkspaceEdit edit;

  CodeAction(std::string title, WorkspaceEdit edit)
      : title(std::move(title)), edit(std::move(edit)) {}

  nlohmann::json toJson() const {
    return {{"title", title}, {"edit", edit.toJson()}};
  }
};

class CompletionParams : public BaseObject {
public:
  TextDocumentIdentifier textDocument;
  LSPPosition position;

  CompletionParams(nlohmann::json &jsonObj)
      : textDocument(jsonObj["textDocument"]), position(jsonObj["position"]) {}
};

enum CompletionItemKind {

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
