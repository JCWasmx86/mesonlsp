import Foundation
import LanguageServerProtocol
import Logging
import MesonAST
import MesonAnalyze
import MesonDocs
import PathKit
import Swifter
import Timing

// There seem to be some name collisions
public typealias MesonVoid = ()

public final class MesonServer: LanguageServer {
  static let LOG = Logger(label: "LanguageServer::MesonServer")
  var onExit: () -> MesonVoid
  var path: String?
  var tree: MesonTree?
  var ns: TypeNamespace
  var memfiles: [String: String] = [:]
  var server: HttpServer
  var docs: MesonDocs = MesonDocs()

  public init(client: Connection, onExit: @escaping () -> MesonVoid) {
    self.onExit = onExit
    self.ns = TypeNamespace()
    self.server = HttpServer()
    for i in 65000...65550 {
      do {
        try self.server.start(
          in_port_t(i),
          forceIPv4: false,
          priority: DispatchQoS.QoSClass.background
        )
        MesonServer.LOG.info("Port: \(i)")
        break
      } catch {}
    }
    super.init(client: client)
    self.server["/"] = { _ in return HttpResponse.ok(.text(self.generateHTML())) }
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
    _register(MesonServer.didSaveDocument)
    _register(MesonServer.hover)
    _register(MesonServer.declaration)
    _register(MesonServer.definition)
    _register(MesonServer.formatting)
    _register(MesonServer.documentSymbol)
    _register(MesonServer.complete)
  }

  func complete(_ req: Request<CompletionRequest>) {
    let begin = clock()
    var arr: [CompletionItem] = []
    if let t = self.tree {
      let fp = req.params.textDocument.uri.fileURL!.path
      if let mt = t.findSubdirTree(file: fp) {
        if mt.ast != nil, let content = self.getContents(file: fp) {
          let pos = req.params.position
          let line = pos.line
          let column = pos.utf16index
          let lines = content.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
          MesonServer.LOG.info("Completion at: [\(line):\(column)]")
          if line < lines.count {
            let str = lines[line]
            let prev = str.prefix(column + 1).description.trimmingCharacters(
              in: NSCharacterSet.whitespaces
            )
            if prev.hasSuffix("."), let t = self.tree, let md = t.metadata {
              var exprTypes: [Type]?
              var s: Set<String> = []
              if let idexpr = md.findIdentifierAt(fp, line, column - 1) {
                MesonServer.LOG.info("Found id expr: \(idexpr.id)")
                exprTypes = idexpr.types
              } else if let fc = md.findFullFunctionCallAt(fp, line, column - 1), fc.function != nil
              {
                MesonServer.LOG.info("Found function expr: \(fc.functionName())")
                exprTypes = fc.types
              } else if let me = md.findFullMethodCallAt(fp, line, column - 1), me.method != nil {
                MesonServer.LOG.info("Found method expr: \(me.method!.id())")
                exprTypes = me.types
              }
              if let types = exprTypes {
                for t in types {
                  for m in t.methods {
                    MesonServer.LOG.info("Inserting completion: \(m.name)")
                    s.insert(m.name)
                  }
                  if t is AbstractObject {
                    var p = (t as! AbstractObject).parent
                    while p != nil {
                      for m in p!.methods {
                        MesonServer.LOG.info("Inserting completion: \(m.name)")
                        s.insert(m.name)
                      }
                      p = p!.parent
                    }
                  }
                }
                for c in s { arr.append(CompletionItem(label: c, kind: .method)) }
              }
            } else if let t = self.tree, let md = t.metadata {
              MesonServer.LOG.info("\(column) \(column - 3)")
              if let idexpr = md.findIdentifierAt(fp, line, column), idexpr.parent is ArgumentList {
                let callExpr = idexpr.parent!.parent!
                var usedKwargs: Set<String> = []
                for arg in (idexpr.parent as! ArgumentList).args where arg is Kwarg {
                  MesonServer.LOG.info("Found already used kwarg: \((arg as! Kwarg).name)")
                  usedKwargs.insert((arg as! Kwarg).name)
                }
                var s: Set<String> = []
                if callExpr is FunctionExpression,
                  let f = (callExpr as! FunctionExpression).function
                {
                  for arg in f.args where arg is Kwarg {
                    MesonServer.LOG.info("Adding kwarg to completion list: \((arg as! Kwarg).name)")
                    s.insert((arg as! Kwarg).name)
                  }
                } else if callExpr is MethodExpression,
                  let m = (callExpr as! MethodExpression).method
                {
                  for arg in m.args where arg is Kwarg {
                    MesonServer.LOG.info("Adding kwarg to completion list: \((arg as! Kwarg).name)")
                    s.insert((arg as! Kwarg).name)
                  }
                }
                for c in s where !usedKwargs.contains(c) {
                  arr.append(CompletionItem(label: c, kind: .keyword, insertText: "\(c): "))
                }
              }
            }
          } else {
            MesonServer.LOG.error("Line out of bounds: \(line) > \(lines.count)")
          }  // 1. Get the nearest node
          // 2. If it is an identifier and parent is build_definition/iterS/selectS
          // 2.1. Calculate function names
          // 2.2. Calculate matching identifier names
          // 3. If it is an identifier and parent is keyworditem/methodcall/functionexpression
          // 3.1. Calculate, whether it matches kwargs
          // 4. If it is an expression like this "<sth>.", attempt to deduce the methods
          // of <sth>
        }
      }
    }
    req.reply(CompletionList(isIncomplete: false, items: arr))
    Timing.INSTANCE.registerMeasurement(name: "complete", begin: begin, end: clock())
  }

  func documentSymbol(_ req: Request<DocumentSymbolRequest>) {
    let begin = clock()
    if let t = self.tree {
      if let mt = t.findSubdirTree(file: req.params.textDocument.uri.fileURL!.path) {
        if let ast = mt.ast {
          let sv = SymbolCodeVisitor()
          var rep: [SymbolInformation] = []
          ast.visit(visitor: sv)
          for si in sv.symbols {
            let name = si.name
            let range =
              Position(
                line: Int(si.startLine),
                utf16index: Int(si.startColumn)
              )..<Position(line: Int(si.endLine), utf16index: Int(si.endColumn))
            let kind = SymbolKind(rawValue: Int(si.kind))
            rep.append(
              SymbolInformation(
                name: name,
                kind: kind,
                location: Location(uri: req.params.textDocument.uri, range: range)
              )
            )
          }
          req.reply(.symbolInformation(rep))
          Timing.INSTANCE.registerMeasurement(name: "documentSymbol", begin: begin, end: clock())
          return
        }
      }
    }
    req.reply(.symbolInformation([]))
    Timing.INSTANCE.registerMeasurement(name: "documentSymbol", begin: begin, end: clock())
  }

  func formatting(_ req: Request<DocumentFormattingRequest>) {
    let begin = clock()
    do {
      MesonServer.LOG.info("Formatting \(req.params.textDocument.uri.fileURL!.path)")
      if let contents = self.getContents(file: req.params.textDocument.uri.fileURL!.path) {
        if let formatted = try formatFile(content: contents, params: req.params.options) {
          // TODO: Do this better
          let range = Position(line: 0, utf16index: 0)..<Position(line: 5_000_000, utf16index: 2048)
          let edit = TextEdit(range: range, newText: formatted)
          req.reply([edit])
          Timing.INSTANCE.registerMeasurement(name: "formatting", begin: begin, end: clock())
          return
        } else {
          MesonServer.LOG.error("Unable to format file")
        }
      } else {
        MesonServer.LOG.error("Unable to read file")
      }
    } catch {
      MesonServer.LOG.error("Error formatting file \(error)")
      req.reply(
        Result.failure(
          ResponseError(code: .internalError, message: "Unable to format using muon: \(error)")
        )
      )
      Timing.INSTANCE.registerMeasurement(name: "formatting", begin: begin, end: clock())
      return
    }
    req.reply(
      Result.failure(
        ResponseError(
          code: .internalError,
          message: "Either failed to read the input file or to format using muon"
        )
      )
    )
    Timing.INSTANCE.registerMeasurement(name: "formatting", begin: begin, end: clock())
  }

  func getContents(file: String) -> String? {
    if let sf = self.memfiles[file] { return sf }
    return try? String(contentsOfFile: file)
  }

  func hover(_ req: Request<HoverRequest>) {
    let beginHover = clock()
    let location = req.params.position
    let file = req.params.textDocument.uri.fileURL?.path
    var content: String?
    var requery = true
    var function: Function?
    if let m = self.tree!.metadata!.findMethodCallAt(file!, location.line, location.utf16index) {
      if m.method != nil {
        function = m.method!
        content = m.method!.parent.toString() + "." + m.method!.name
      }
    }
    if content == nil,
      let f = self.tree!.metadata!.findFunctionCallAt(file!, location.line, location.utf16index)
    {
      if f.function != nil {
        function = f.function!
        content = f.function!.name
      }
    }
    if content == nil,
      let f = self.tree!.metadata!.findIdentifierAt(file!, location.line, location.utf16index)
    {
      if !f.types.isEmpty {
        content = f.types.map({ $0.toString() }).joined(separator: "|")
        requery = false
      }
    }
    if content == nil,
      let tuple = self.tree!.metadata!.findKwargAt(file!, location.line, location.utf16index)
    {
      let kw = tuple.0
      let f = tuple.1
      if let k = kw.key as? IdExpression { content = f.id() + "<" + k.id + ">" }
    }
    if content != nil && requery {
      if function == nil {  // Kwarg docs
        let d = self.docs.find_docs(id: content!)
        content = d ?? content!
      } else {
        let d = self.docs.find_docs(id: content!)
        if let mdocs = d {
          var str = "`" + content! + "`\n\n" + mdocs + "\n\n"
          for arg in function!.args {
            if let pa = arg as? PositionalArgument {
              str += "- "
              if pa.opt { str += "\\[" }
              str += "`" + pa.name + "`"
              str += " "
              str += pa.types.map({ $0.toString() }).joined(separator: "|")
              if pa.varargs { str += "..." }
              if pa.opt { str += "\\]" }
              str += "\n"
            } else if let kw = arg as? Kwarg {
              str += "- "
              if kw.opt { str += "\\[" }
              str += "`" + kw.name + "`"
              str += ": "
              str += kw.types.map({ $0.toString() }).joined(separator: "|")
              if kw.opt { str += "\\]" }
              str += "\n"
            }
          }
          if function!.returnTypes.count > 0 {
            str +=
              "\n*Returns:* " + function!.returnTypes.map({ $0.toString() }).joined(separator: "|")
          }
          content = str
        }
      }
    }
    req.reply(
      HoverResponse(
        contents: content == nil
          ? .markedStrings([])
          : .markupContent(MarkupContent(kind: .markdown, value: content ?? "")),
        range: nil
      )
    )
    let endHover = clock()
    Timing.INSTANCE.registerMeasurement(name: "hover", begin: Int(beginHover), end: Int(endHover))
  }

  func declaration(_ req: Request<DeclarationRequest>) {
    let beginDeclaration = clock()
    let location = req.params.position
    let file = req.params.textDocument.uri.fileURL?.path
    if let i = self.tree!.metadata!.findIdentifierAt(file!, location.line, location.utf16index) {
      if let t = findDeclaration(node: i) {
        let newFile = t.0
        let line = t.1
        let column = t.2
        let range = Range(LanguageServerProtocol.Position(line: Int(line), utf16index: Int(column)))
        MesonServer.LOG.info("Found declaration")
        req.reply(
          .locations([.init(uri: DocumentURI(URL(fileURLWithPath: newFile)), range: range)])
        )
        let endDeclaration = clock()
        Timing.INSTANCE.registerMeasurement(
          name: "declaration",
          begin: Int(beginDeclaration),
          end: Int(endDeclaration)
        )
        return
      } else {
        MesonServer.LOG.info("Found identifier")
      }
    }

    if let sd = self.tree!.metadata!.findSubdirCallAt(file!, location.line, location.utf16index) {
      let path = Path(Path(file!).parent().description + "/" + sd.subdirname + "/meson.build")
        .description
      let range = Range(LanguageServerProtocol.Position(line: Int(0), utf16index: Int(0)))
      req.reply(.locations([.init(uri: DocumentURI(URL(fileURLWithPath: path)), range: range)]))
      let endDeclaration = clock()
      Timing.INSTANCE.registerMeasurement(
        name: "declaration",
        begin: Int(beginDeclaration),
        end: Int(endDeclaration)
      )
      return
    }
    MesonServer.LOG.warning("Found no declaration")
    req.reply(.locations([]))
    let endDeclaration = clock()
    Timing.INSTANCE.registerMeasurement(
      name: "declaration",
      begin: Int(beginDeclaration),
      end: Int(endDeclaration)
    )
  }

  func definition(_ req: Request<DefinitionRequest>) {
    let beginDefinition = clock()
    let location = req.params.position
    let file = req.params.textDocument.uri.fileURL?.path
    if let i = self.tree!.metadata!.findIdentifierAt(file!, location.line, location.utf16index) {
      if let t = findDeclaration(node: i) {
        let newFile = t.0
        let line = t.1
        let column = t.2
        let range = Range(LanguageServerProtocol.Position(line: Int(line), utf16index: Int(column)))
        MesonServer.LOG.info("Found definition")
        req.reply(
          .locations([.init(uri: DocumentURI(URL(fileURLWithPath: newFile)), range: range)])
        )
        let endDefinition = clock()
        Timing.INSTANCE.registerMeasurement(
          name: "definition",
          begin: Int(beginDefinition),
          end: Int(endDefinition)
        )
        return
      } else {
        MesonServer.LOG.info("Found identifier")
      }
    }

    if let sd = self.tree!.metadata!.findSubdirCallAt(file!, location.line, location.utf16index) {
      let path = Path(Path(file!).parent().description + "/" + sd.subdirname + "/meson.build")
        .description
      let range = Range(LanguageServerProtocol.Position(line: Int(0), utf16index: Int(0)))
      req.reply(.locations([.init(uri: DocumentURI(URL(fileURLWithPath: path)), range: range)]))
      let endDefinition = clock()
      Timing.INSTANCE.registerMeasurement(
        name: "definition",
        begin: Int(beginDefinition),
        end: Int(endDefinition)
      )
      return
    }
    MesonServer.LOG.warning("Found no definition")
    req.reply(.locations([]))
    let endDefinition = clock()
    Timing.INSTANCE.registerMeasurement(
      name: "definition",
      begin: Int(beginDefinition),
      end: Int(endDefinition)
    )
  }

  func rebuildTree() {
    queue.async {
      let beginRebuilding = clock()
      if self.tree != nil && self.tree!.metadata != nil {
        for k in self.tree!.metadata!.diagnostics.keys {
          if self.tree!.metadata!.diagnostics[k] == nil { continue }
          let arr: [Diagnostic] = []
          self.client.send(
            PublishDiagnosticsNotification(
              uri: DocumentURI(URL(fileURLWithPath: k)),
              diagnostics: arr
            )
          )
        }
      }
      let endClearing = clock()
      Timing.INSTANCE.registerMeasurement(
        name: "clearingDiagnostics",
        begin: Int(beginRebuilding),
        end: Int(endClearing)
      )
      let tmptree = try! MesonTree(
        file: self.path! + "/meson.build",
        ns: self.ns,
        memfiles: self.memfiles
      )
      let endParsingEntireTree = clock()
      Timing.INSTANCE.registerMeasurement(
        name: "parsingEntireTree",
        begin: Int(endClearing),
        end: Int(endParsingEntireTree)
      )
      tmptree.analyzeTypes()
      let endAnalyzingTypes = clock()
      Timing.INSTANCE.registerMeasurement(
        name: "analyzingTypes",
        begin: Int(endParsingEntireTree),
        end: Int(endAnalyzingTypes)
      )
      if tmptree.metadata == nil {
        let endRebuilding = clock()
        Timing.INSTANCE.registerMeasurement(
          name: "rebuildTree",
          begin: Int(beginRebuilding),
          end: Int(endRebuilding)
        )
        return
      }
      for k in tmptree.metadata!.diagnostics.keys {
        if tmptree.metadata!.diagnostics[k] == nil { continue }
        var arr: [Diagnostic] = []
        let diags = tmptree.metadata!.diagnostics[k]!
        MesonServer.LOG.info("Publishing \(diags.count) diagnostics for \(k)")
        for diag in diags {
          if diag.severity == .error {
            MesonServer.LOG.error("\(diag.message)")
          } else {
            MesonServer.LOG.warning("\(diag.message)")
          }
          let s = LanguageServerProtocol.Position(
            line: Int(diag.startLine),
            utf16index: Int(diag.startColumn)
          )
          let e = LanguageServerProtocol.Position(
            line: Int(diag.endLine),
            utf16index: Int(diag.endColumn)
          )
          let sev: DiagnosticSeverity = diag.severity == .error ? .error : .warning
          arr.append(Diagnostic(range: s..<e, severity: sev, source: nil, message: diag.message))
        }
        self.client.send(
          PublishDiagnosticsNotification(
            uri: DocumentURI(URL(fileURLWithPath: k)),
            diagnostics: arr
          )
        )
      }
      let endSendingDiagnostics = clock()
      Timing.INSTANCE.registerMeasurement(
        name: "sendingDiagnostics",
        begin: Int(endAnalyzingTypes),
        end: Int(endSendingDiagnostics)
      )
      Timing.INSTANCE.registerMeasurement(
        name: "rebuildTree",
        begin: Int(beginRebuilding),
        end: Int(endSendingDiagnostics)
      )
      self.tree = tmptree
    }
  }

  func openDocument(_ note: Notification<DidOpenTextDocumentNotification>) {

  }

  func didSaveDocument(_ note: Notification<DidSaveTextDocumentNotification>) {
    let file = note.params.textDocument.uri.fileURL?.path
    // Either the saves were changed or dropped, so use the contents
    // of the file
    MesonServer.LOG.info("[Save] Dropping \(file!) from memcache")
    self.memfiles.removeValue(forKey: file!)
    self.rebuildTree()
  }

  func closeDocument(_ note: Notification<DidCloseTextDocumentNotification>) {
    let file = note.params.textDocument.uri.fileURL?.path
    // Either the saves were changed or dropped, so use the contents
    // of the file
    MesonServer.LOG.info("[Close] Dropping \(file!) from memcache")
    self.memfiles.removeValue(forKey: file!)
    self.rebuildTree()
  }

  func changeDocument(_ note: Notification<DidChangeTextDocumentNotification>) {
    let file = note.params.textDocument.uri.fileURL?.path
    MesonServer.LOG.info("[Change] Adding \(file!) to memcache")
    self.memfiles[file!] = note.params.contentChanges[0].text
    self.rebuildTree()
  }

  func capabilities() -> ServerCapabilities {
    return ServerCapabilities(
      textDocumentSync: .options(
        TextDocumentSyncOptions(openClose: true, change: .full, save: .bool(true))
      ),
      hoverProvider: .bool(true),
      completionProvider: .some(
        CompletionOptions(resolveProvider: false, triggerCharacters: ["."])
      ),
      definitionProvider: .bool(true),
      documentHighlightProvider: .bool(true),
      documentSymbolProvider: .bool(true),
      workspaceSymbolProvider: .bool(true),
      documentFormattingProvider: .bool(true),
      declarationProvider: .bool(true)
    )
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
    self.server.stop()
    request.reply(VoidResponse())
  }
  func exit(_ notification: Notification<ExitNotification>) {
    self.prepareForExit()
    self.onExit()
  }

  func generateHTML() -> String {
    let header = """
      		<!DOCTYPE html>
      		<html>
      		<head>
      		<meta http-equiv="refresh" content="5" />
      		<style>
      		table {
      			font-family: arial, sans-serif;
      			border-collapse: collapse;
      			width: 100%;
      		}

      		td, th {
      			border: 1px solid #dddddd;
      			text-align: left;
      			padding: 8px;
      		}

      		tr:nth-child(even) {
      			background-color: #dddddd;
      		}
      		</style>
      		</head>
      		<body>

      		<h2>Timing information</h2>

      		<table>
      			<tr>
      				<th>Identifier</th>
      				<th>Hits</th>
      				<th>Min</th>
      				<th>Max</th>
      				<th>Median</th>
      				<th>Average</th>
      				<th>Standard deviation</th>
      				<th>Sum</th>
      			</tr>
      	"""
    var str = ""
    for t in Timing.INSTANCE.timings() {
      str.append(
        "<tr>" + "<td>\(t.name)</td>" + "<td>\(t.hits())</td>" + "<td>\(t.min().round(to: 2))</td>"
          + "<td>\(t.max().round(to: 2))</td>" + "<td>\(t.median().round(to: 2))</td>"
          + "<td>\(t.average().round(to: 2))</td>" + "<td>\(t.stddev().round(to: 2))</td>"
          + "<td>\(t.sum().round(to: 2))</td></tr>"
      )
    }
    let footer = """
      		</table>

      		</body>
      		</html>
      	"""
    return header + str + footer
  }
}

extension Double {
  func round(to places: Int) -> Double {
    let divisor = pow(10.0, Double(places))
    return (self * divisor).rounded() / divisor
  }
}
