import Foundation
import LanguageServerProtocol
import MesonAST
import MesonAnalyze
import PathKit

// There seem to be some name collisions
public typealias MesonVoid = ()

public final class MesonServer: LanguageServer {
  var onExit: () -> MesonVoid
  var path: String?
  var tree: MesonTree?
  var ns: TypeNamespace

  public init(client: Connection, onExit: @escaping () -> MesonVoid) {
    self.onExit = onExit
    self.ns = TypeNamespace()

    super.init(client: client)
  }

  public func prepareForExit() {

  }

  public override func _registerBuiltinHandlers() {
    _register(MesonServer.initialize)
    _register(MesonServer.clientInitialized)
    _register(MesonServer.cancelRequest)
    _register(MesonServer.shutdown)
    _register(MesonServer.exit)
    _register(MesonServer.openDocument)
    _register(MesonServer.closeDocument)
    _register(MesonServer.changeDocument)
    _register(MesonServer.hover)
    _register(MesonServer.declaration)
    _register(MesonServer.definition)
  }

  func hover(_ req: Request<HoverRequest>) {
    let location = req.params.position
    let file = req.params.textDocument.uri.fileURL?.path
    var content: String?
    if let m = self.tree!.metadata!.findMethodCallAt(file!, location.line, location.utf16index) {
      if m.method != nil { content = m.method!.parent.toString() + "." + m.method!.name }
    }
    if content == nil,
      let f = self.tree!.metadata!.findFunctionCallAt(file!, location.line, location.utf16index)
    {
      if f.function != nil { content = f.function!.name }
    }
    if content == nil,
      let f = self.tree!.metadata!.findIdentifierAt(file!, location.line, location.utf16index)
    {
      if !f.types.isEmpty { content = f.types.map({ $0.toString() }).joined(separator: "|") }
    }
    req.reply(
      HoverResponse(
        contents: content == nil
          ? .markedStrings([])
          : .markupContent(MarkupContent(kind: .markdown, value: content ?? "FOO")), range: nil))
  }

  func declaration(_ req: Request<DeclarationRequest>) {
    let location = req.params.position
    let file = req.params.textDocument.uri.fileURL?.path
    if let i = self.tree!.metadata!.findIdentifierAt(file!, location.line, location.utf16index) {
      if let t = findDeclaration(node: i) {
        let newFile = t.0
        let line = t.1
        let column = t.2
        let range = Range(LanguageServerProtocol.Position(line: Int(line), utf16index: Int(column)))
        print("Found declaration")
        req.reply(
          .locations([.init(uri: DocumentURI(URL(fileURLWithPath: newFile)), range: range)]))
        return
      } else {
        print("Found identifier")
      }
    }

    if let sd = self.tree!.metadata!.findSubdirCallAt(file!, location.line, location.utf16index) {
      let path = Path(Path(file!).parent().description + "/" + sd.subdirname + "/meson.build")
        .description
      let range = Range(LanguageServerProtocol.Position(line: Int(0), utf16index: Int(0)))
      req.reply(.locations([.init(uri: DocumentURI(URL(fileURLWithPath: path)), range: range)]))
      return
    }
    print("Found no declaration")
    req.reply(.locations([]))
    return
  }

  func definition(_ req: Request<DefinitionRequest>) {
    let location = req.params.position
    let file = req.params.textDocument.uri.fileURL?.path
    if let i = self.tree!.metadata!.findIdentifierAt(file!, location.line, location.utf16index) {
      if let t = findDeclaration(node: i) {
        let newFile = t.0
        let line = t.1
        let column = t.2
        let range = Range(LanguageServerProtocol.Position(line: Int(line), utf16index: Int(column)))
        print("Found definition")
        req.reply(
          .locations([.init(uri: DocumentURI(URL(fileURLWithPath: newFile)), range: range)]))
        return
      } else {
        print("Found identifier")
      }
    }

    if let sd = self.tree!.metadata!.findSubdirCallAt(file!, location.line, location.utf16index) {
      let path = Path(Path(file!).parent().description + "/" + sd.subdirname + "/meson.build")
        .description
      let range = Range(LanguageServerProtocol.Position(line: Int(0), utf16index: Int(0)))
      req.reply(.locations([.init(uri: DocumentURI(URL(fileURLWithPath: path)), range: range)]))
      return
    }
    print("Found no definition")
    req.reply(.locations([]))
    return
  }

  func rebuildTree() {
    queue.async {
      self.tree = try! MesonTree(file: self.path! + "/meson.build", ns: self.ns)
      self.tree!.analyzeTypes()
      if self.tree == nil || self.tree!.metadata == nil { return }
      for k in self.tree!.metadata!.diagnostics.keys {
        if self.tree!.metadata!.diagnostics[k] == nil { continue }
        var arr: [Diagnostic] = []
        let diags = self.tree!.metadata!.diagnostics[k]!
        print("Publishing \(diags.count) diagnostics for \(k)")
        for diag in diags {
        	print(">>", diag.message)
          let s = LanguageServerProtocol.Position(
            line: Int(diag.startLine), utf16index: Int(diag.startColumn))
          let e = LanguageServerProtocol.Position(
            line: Int(diag.endLine), utf16index: Int(diag.endColumn))
          let sev: DiagnosticSeverity = diag.severity == .error ? .error : .warning
          arr.append(Diagnostic(range: s..<e, severity: sev, source: nil, message: diag.message))
        }
        self.client.send(
          PublishDiagnosticsNotification(
            uri: DocumentURI(URL(fileURLWithPath: k)), diagnostics: arr))
      }
    }
  }

  func openDocument(_ note: Notification<DidOpenTextDocumentNotification>) { self.rebuildTree() }

  func closeDocument(_ note: Notification<DidCloseTextDocumentNotification>) {

  }

  func changeDocument(_ note: Notification<DidChangeTextDocumentNotification>) {
    self.rebuildTree()
  }

  func capabilities() -> ServerCapabilities {
    return ServerCapabilities(
      textDocumentSync: .options(TextDocumentSyncOptions(openClose: true, change: .full)),
      hoverProvider: .bool(true), definitionProvider: .bool(true),
      documentHighlightProvider: .bool(true), documentSymbolProvider: .bool(true),
      workspaceSymbolProvider: .bool(true), declarationProvider: .bool(true))
  }

  func initialize(_ req: Request<InitializeRequest>) {
    let p = req.params
    if p.rootPath == nil { fatalError("Nothing else supported other than using rootPath") }
    self.path = p.rootPath
    self.rebuildTree()
    req.reply(InitializeResult(capabilities: self.capabilities()))
  }

  func clientInitialized(_: Notification<InitializedNotification>) {
    // Nothing to do.
  }
  func cancelRequest(_ notification: Notification<CancelRequestNotification>) {
    // No cancellation for anything supported (yet?)
  }
  func shutdown(_ request: Request<ShutdownRequest>) {
    self.prepareForExit()
    request.reply(VoidResponse())
  }
  func exit(_ notification: Notification<ExitNotification>) {
    self.prepareForExit()
    self.onExit()
  }
}
