import LanguageServerProtocol
import MesonAnalyze

public final class MesonServer: LanguageServer {
  var onExit: () -> ()
  var path: String?
  var tree: MesonTree?

  public init(client: Connection, onExit: @escaping () -> () = {}) {
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
  }

  func capabilities() -> ServerCapabilities {
		return ServerCapabilities(
      textDocumentSync: .options(TextDocumentSyncOptions(
        openClose: true,
        change: .full
      )),
      hoverProvider: .bool(true),
      definitionProvider: .bool(true),
      documentHighlightProvider: .bool(true),
      documentSymbolProvider: .bool(true),
      workspaceSymbolProvider: .bool(true),
      declarationProvider: .bool(true)
    )
  }

  func initialize(_ req: Request<InitializeRequest>) {
  	let p = req.params
  	if p.rootPath == nil {
  		fatalError("Nothing else supported other than using rootPath")
  	}
  	self.path = p.rootPath
  	queue.async {
			self.tree = try! MesonTree(file: self.path! + "/meson.build")
  	}
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
