import LanguageServerProtocol
import MesonAnalyze

// There seem to be some name collisions
public typealias MesonVoid = ()

public final class MesonServer: LanguageServer {
  var onExit: () -> MesonVoid
  var path: String?
  var tree: MesonTree?

  public init(client: Connection, onExit: @escaping () -> MesonVoid) {
    self.onExit = onExit

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
    req.reply(
      HoverResponse(
        contents: .markupContent(MarkupContent(kind: .markdown, value: "FOO")), range: nil))
  }

  func declaration(_ req: Request<DeclarationRequest>) {
    let range = Range(Position(line: 0, utf16index: 0))
    req.reply(.locations([.init(uri: req.params.textDocument.uri, range: range)]))
  }

  func definition(_ req: Request<DefinitionRequest>) {
    let range = Range(Position(line: 0, utf16index: 0))
    req.reply(.locations([.init(uri: req.params.textDocument.uri, range: range)]))
  }

  func rebuildTree() {
    queue.async {
      self.tree = try! MesonTree(file: self.path! + "/meson.build")
      self.tree!.analyzeTypes()
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
