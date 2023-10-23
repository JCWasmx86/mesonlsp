import Dispatch
import Foundation
import IOUtils
import LanguageServerProtocol
import Logging
import MesonAnalyze
import MesonAST
import MesonDocs
import Timing
import Wrap

#if !os(Windows)
  import Swifter
#endif

// There seem to be some name collisions
public typealias MesonVoid = ()

public final class MesonServer: LanguageServer {
  static let LOG = Logger(label: "LanguageServer::MesonServer")
  static let MIN_PORT = 65000
  static let MAX_PORT = 65550
  var memfilesQueue = DispatchQueue(label: "mesonserver.memfiles")
  var onExit: () -> MesonVoid
  var path: String?
  var tree: MesonTree?
  var ns: TypeNamespace
  var memfiles: [String: String] = [:]
  var parseSubprojectTask: Task<(), Error>?
  var parseTask: Task<(), Error>?
  #if !os(Windows)
    var server: HttpServer
  #endif
  var docs: MesonDocs = MesonDocs()
  var openFiles: Set<String> = []
  var openSubprojectFiles: [String: Set<String>] = [:]
  var astCache: [String: Node] = [:]
  var astCaches: [String: [String: Node]] = [:]
  var tasks: [String: Task<(), Error>] = [:]
  let interval = DispatchTimeInterval.seconds(60)
  let mtimeChecker = DispatchTimeInterval.milliseconds(300)
  var subprojects: SubprojectState?
  var mapper: FileMapper = FileMapper()
  var token: ProgressToken?
  var subprojectsDirectoryMtime: Date?
  var pkgNames: Set<String> = []
  let codeActionState = CodeActionState()
  var stats: [String: [(Date, UInt64)]] = [:]
  var analysisOptions = AnalysisOptions()
  var otherSettings = OtherSettings(
    ignoreDiagnosticsFromSubprojects: nil,
    neverDownloadAutomatically: false
  )

  public init(client: Connection, onExit: @escaping () -> MesonVoid) {
    self.onExit = onExit
    self.ns = TypeNamespace()
    Task.detached {
      do { try await WrapDB.INSTANCE.initDB() } catch {
        Self.LOG.error("Failed to init WrapDB: \(error)")
      }
    }
    #if !os(Windows)
      self.server = HttpServer()
      for i in Self.MIN_PORT...Self.MAX_PORT {
        do {
          try self.server.start(
            in_port_t(i),
            forceIPv4: false,
            priority: DispatchQoS.QoSClass.background
          )
          Self.LOG.info("Port: \(i)")
          break
        } catch {}
      }
      super.init(client: client)
      self.server["/"] = { _ in return HttpResponse.ok(.text(self.generateHTML())) }
      self.server["/caches"] = { _ in return HttpResponse.ok(.text(self.generateCacheHTML())) }
      self.server["/count"] = { _ in return HttpResponse.ok(.text(self.generateCountHTML())) }
      self.server["/status"] = { _ in return HttpResponse.ok(.text(self.generateStatusHTML())) }
      #if os(Linux)
        self.server["/stats"] = { _ in return HttpResponse.ok(.text(self.generateStatsHTML())) }
      #endif
    #else
      super.init(client: client)
    #endif

    #if os(Linux)
      stats["notifications"] = []
      stats["requests"] = []
      stats["memory_usage"] = []

      let total = collectStats()[2]
      let date = Date()
      self.stats["notifications"]!.append((date, UInt64(self.notificationCount)))
      self.stats["requests"]!.append((date, UInt64(self.requestCount)))
      self.stats["memory_usage"]!.append((date, total))

      self.queue.asyncAfter(deadline: .now() + interval) {
        self.sendStats()
        self.scheduleNextTask()
      }
    #endif
    let task = Process()
    let pipe = Pipe()
    let inPipe = Pipe()
    task.standardOutput = pipe
    task.arguments = ["--list-package-names"]
    inPipe.fileHandleForWriting.write("".data(using: .utf8)!)
    inPipe.fileHandleForWriting.closeFile()
    task.standardInput = inPipe
    task.executableURL = URL(fileURLWithPath: "/usr/bin/pkg-config")
    do {
      try task.run()
      task.waitUntilExit()
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      let output = String(data: data, encoding: .utf8)
      output!.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).forEach {
        self.pkgNames.insert(String($0))
      }
    } catch { Self.LOG.error("\(error)") }
  }

  private func checkMtime() {
    if let date = self.getDirectoryModificationTime(
      path: self.path! + "\(Path.separator)subprojects"
    ) {
      if let oldDate = self.subprojectsDirectoryMtime {
        if date > oldDate {
          Self.LOG.info("subprojects/ was modified. Recreating subprojects")
          if let t = self.parseSubprojectTask { t.cancel() }
          self.parseSubprojectTask = Task.detached {
            self.subprojects = nil
            await self.setupSubprojects()
          }
        }
      } else {
        Self.LOG.info("subprojects/ was added. Setting up subprojects")
        if let t = self.parseSubprojectTask { t.cancel() }
        self.parseSubprojectTask = Task.detached { await self.setupSubprojects() }
      }
    }
  }

  private func scheduleNextMtimeCheck() {
    self.queue.asyncAfter(deadline: .now() + mtimeChecker) {
      self.checkMtime()
      self.scheduleNextMtimeCheck()
    }
  }

  #if os(Linux)
    private func sendStats() {
      Self.LOG.info("Collecting stats")
      let stats = collectStats()
      let heap = stats[0]
      let stack = stats[1]
      let total = stats[2]
      let heapS = formatWithUnits(heap)
      let stackS = formatWithUnits(stack)
      let totalS = formatWithUnits(total)
      Self.LOG.info("Stack: \(stackS) Heap: \(heapS) Total: \(totalS)")
      let date = Date()
      self.stats["notifications"]!.append((date, UInt64(self.notificationCount)))
      self.stats["requests"]!.append((date, UInt64(self.requestCount)))
      self.stats["memory_usage"]!.append((date, total))
      for n in self.requests { self.stats[n.0] = (self.stats[n.0] ?? []) + [(date, UInt64(n.1))] }

      for n in self.notifications {
        self.stats[n.0] = (self.stats[n.0] ?? []) + [(date, UInt64(n.1))]
      }
    }

    private func scheduleNextTask() {
      self.queue.asyncAfter(deadline: .now() + interval) {
        self.sendStats()
        self.scheduleNextTask()
      }
    }
  #endif

  public func prepareForExit() {
    if let t = self.parseSubprojectTask { t.cancel() }
    if let t = self.parseTask { t.cancel() }
    self.tasks.values.forEach { $0.cancel() }
    Self.LOG.warning("Killing \(Processes.PROCESSES.count) processes")
    if let t = self.token {
      let endMessage = WorkDoneProgress(
        token: t,
        value: WorkDoneProgressKind.end(WorkDoneProgressEnd())
      )
      self.client.send(endMessage)
    }
    Processes.CLEANUP_HANDLER()
  }

  public override func _registerBuiltinHandlers() {
    _register(Self.initialize)
    _register(Self.clientInitialized)
    _register(Self.cancelRequest)
    _register(Self.shutdown)
    _register(Self.exit)
    _register(Self.openDocument)
    _register(Self.closeDocument)
    _register(Self.changeDocument)
    _register(Self.didSaveDocument)
    _register(Self.hover)
    _register(Self.declaration)
    _register(Self.definition)
    _register(Self.formatting)
    _register(Self.documentSymbol)
    _register(Self.complete)
    _register(Self.highlight)
    _register(Self.inlayHints)
    _register(Self.didCreateFiles)
    _register(Self.didDeleteFiles)
    _register(Self.codeActions)
    _register(Self.rename)
    _register(Self.semanticTokenFull)
    _register(Self.didChangeConfiguration)
  }

  private func semanticTokenFull(_ req: Request<DocumentSemanticTokensRequest>) {
    let begin = clock()
    if let t = self.findTree(req.params.textDocument.uri), let ast = t.ast {
      let stv = SemanticTokenVisitor()
      ast.visit(visitor: stv)
      req.reply(DocumentSemanticTokensResponse(data: stv.finish()))
    } else {
      req.reply(DocumentSemanticTokensResponse(data: []))
    }
    Timing.INSTANCE.registerMeasurement(name: "semanticTokens", begin: begin, end: clock())
  }

  private func rename(_ req: Request<RenameRequest>) {
    let params = req.params
    guard let t = self.tree else {
      req.reply(.failure(ResponseError(code: .requestFailed, message: "No tree available!")))
      return
    }
    guard
      let id = t.metadata?.findIdentifierAt(
        params.textDocument.uri.fileURL!.absoluteURL.path,
        params.position.line,
        params.position.utf16index
      )
    else {
      req.reply(
        .failure(
          ResponseError(code: .requestFailed, message: "No identifier found at this location!")
        )
      )
      return
    }
    if let parentLoop = id.parent as? IterationStatement, parentLoop.containsAsId(id) {
      let lvr = LoopVariableRename(id.id, params.newName, t)
      parentLoop.visit(visitor: lvr)
      req.reply(WorkspaceEdit(changes: lvr.edits))
      return
    }
    if let kw = id.parent as? KeywordItem, kw.key.equals(right: id) {
      req.reply(WorkspaceEdit(changes: [:]))
      return
    }
    if let fn = id.parent as? FunctionExpression, fn.id.equals(right: id) {
      req.reply(WorkspaceEdit(changes: [:]))
      return
    }
    if let fn = id.parent as? MethodExpression, fn.id.equals(right: id) {
      req.reply(WorkspaceEdit(changes: [:]))
      return
    }
    var edits: [DocumentURI: [TextEdit]] = [:]
    for m in t.metadata!.identifiers.keys {
      let ids = t.metadata!.identifiers[m]!
      ids.filter { $0.id == id.id }.forEach {
        let d = DocumentURI(
          URL(fileURLWithPath: Path($0.file.file).normalize().absolute().description)
        )
        let range = Shared.nodeToRange($0)
        let textEdit = TextEdit(range: range, newText: params.newName)
        edits[d] = (edits[d] ?? []) + [textEdit]
      }
    }
    req.reply(WorkspaceEdit(changes: edits))
  }

  private func codeActions(_ req: Request<CodeActionRequest>) {
    let begin = clock()
    let uri = req.params.textDocument.uri
    let range = req.params.range
    let cav = CodeActionVisitor(range)
    let file = uri.fileURL!.absoluteURL.path
    var actions: [CodeAction] = []
    if let tree = self.findTree(uri), tree.ast != nil, let a = tree.findSubdirTree(file: file),
      let a2 = a.ast
    {
      a2.visit(visitor: cav)
      for node in cav.applicableNodes {
        actions += self.codeActionState.apply(uri: uri, node: node, tree: tree)
      }
      if self.tree?.findSubdirTree(
        file: Path(uri.fileURL!.absoluteURL.path).absolute().normalize().description
      ) != nil {
        for node in cav.applicableNodes {
          actions += self.codeActionState.applyToMainTree(
            uri: uri,
            node: node,
            tree: tree,
            subprojects: self.subprojects,
            rootDirectory: self.path!
          )
        }
      }
    }
    Self.LOG.info(
      "Found \(actions.count) code actions at \(uri):\(range): \(actions.map { $0.title })"
    )
    req.reply(
      CodeActionRequestResponse(
        codeActions: actions,
        clientCapabilities: TextDocumentClientCapabilities.CodeAction(
          codeActionLiteralSupport: TextDocumentClientCapabilities.CodeAction
            .CodeActionLiteralSupport(
              codeActionKind: TextDocumentClientCapabilities.CodeAction.CodeActionLiteralSupport
                .CodeActionKind(valueSet: [])
            )
        )
      )
    )
    Timing.INSTANCE.registerMeasurement(name: "codeaction", begin: begin, end: clock())
  }

  private func findTree(_ uri: DocumentURI) -> MesonTree? {
    guard let p = self.path else { return self.tree }
    let rootPath = Path(p).absolute().normalize().description
    if let url = uri.fileURL {
      let filePath = Path(url.absoluteURL.path).absolute().normalize().description
      // dropFirst to drop leading slash
      let relativePath = filePath.replacingOccurrences(of: rootPath, with: "").dropFirst()
        .description
      if relativePath.hasPrefix("subprojects"), let s = self.subprojects {
        let parts = relativePath.split(separator: "/")
        // At least subprojects/<name>/meson.build
        if parts.count < 3 { return self.tree }
        let name = parts[1]
        var found = false
        Self.LOG.info("subprojects/\(name)/")
        let l = s.subprojects.map { $0.realpath }
        Self.LOG.info("\(l)")
        for sp in s.subprojects
        where sp.realpath.hasPrefix("subprojects\(Path.separator)\(name)\(Path.separator)") {
          found = true
          if let t = sp.tree {
            Self.LOG.info("Found subproject `\(sp.description)` for path \(filePath)")
            return t
          }
        }
        // We found a matching subproject, but
        // sadly it contains no MesonTree
        if found { return nil }
      }
    }
    return self.tree
  }

  private func findSubprojectForUri(_ uri: DocumentURI) -> MesonAnalyze.Subproject? {
    guard let p = self.path else { return nil }
    let rootPath = Path(p).absolute().normalize().description
    if let url = uri.fileURL {
      let filePath = Path(url.absoluteURL.path).absolute().normalize().description
      // dropFirst to drop leading slash
      let relativePath = filePath.replacingOccurrences(of: rootPath, with: "").dropFirst()
        .description
      if relativePath.hasPrefix("subprojects"), let s = self.subprojects {
        let parts = relativePath.split(separator: "/")
        // At least subprojects/<name>/meson.build
        if parts.count < 3 { return nil }
        let name = parts[1]
        if name == "packagefiles" || name == "packagecache" { return nil }
        for sp in s.subprojects
        where sp.realpath.hasPrefix("subprojects\(Path.separator)\(name)\(Path.separator)") {
          return sp
        }
      }
    }
    return nil
  }

  private func inlayHints(_ req: Request<InlayHintRequest>) {
    collectInlayHints(self.findTree(req.params.textDocument.uri), req, self.mapper)
  }

  private func highlight(_ req: Request<DocumentHighlightRequest>) {
    highlightTree(self.findTree(req.params.textDocument.uri), req, self.mapper)
  }

  // swiftlint:disable cyclomatic_complexity
  private func complete(_ req: Request<CompletionRequest>) {
    let begin = clock()
    var arr: [CompletionItem] = []
    let fp = req.params.textDocument.uri.fileURL!.path
    if let t = self.tree, let mt = t.findSubdirTree(file: fp), mt.ast != nil,
      let content = self.getContents(file: fp)
    {
      let pos = req.params.position
      let line = pos.line
      let column = pos.utf16index
      let lines = content.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
      Self.LOG.info("Completion at: [\(line):\(column)]")
      if line < lines.count {
        let str = lines[line]
        Self.LOG.info("Entire line: '\(str)'")
        let prev = str.prefix(column + 1).description.trimmingCharacters(in: .whitespaces)
        Self.LOG.info("Prev = '\(prev)'")
        if prev.hasSuffix(".") || (prev.hasSuffix(")") && !prev.hasSuffix(" )")), let t = self.tree,
          let md = t.metadata
        {
          let exprTypes = self.afterDotCompletion(md, fp, line, column)
          if let types = exprTypes {
            let s: Set<MesonAST.Method> = self.fillTypes(types)
            for c in s {
              arr.append(
                CompletionItem(
                  label: c.name,
                  kind: .method,
                  insertText: createTextForFunction(c),
                  insertTextFormat: .snippet
                )
              )
            }
          } else {
            let errorId = self.extractErrorId(prev)
            if let err = errorId {
              let types = md.findAllTypes(fp, err)
              let s: Set<MesonAST.Method> = self.fillTypes(types)
              for c in s {
                arr.append(
                  CompletionItem(
                    label: c.name,
                    kind: .method,
                    insertText: createTextForFunction(c),
                    insertTextFormat: .snippet
                  )
                )
              }
            }
          }
        }
        if let t = self.tree, let md = t.metadata {
          self.subprojectGetVariableSpecialCase(fp, line, column, md, &arr)
          self.dependencySpecialCase(fp, line, column, md, prev, &arr)
          self.getOptionSpecialCase(t, fp, line, column, md, &arr)
          self.sourceFilesSpecialCase(t, fp, line, column, md, &arr)
          if let idexpr = md.findIdentifierAt(fp, line, column),
            let al = idexpr.parent as? ArgumentList
          {
            let callExpr = idexpr.parent!.parent!
            let usedKwargs: Set<String> = self.enumerateUsedKwargs(al)
            let s: Set<String> = self.fillKwargs(callExpr)
            for c in s where !usedKwargs.contains(c) {
              arr.append(
                CompletionItem(
                  label: c,
                  kind: .keyword,
                  insertText: "\(c): ${1:\(c)}",
                  insertTextFormat: .snippet
                )
              )
            }
          } else if let idexpr = md.findIdentifierAt(fp, line, column) {
            let currId = idexpr.id
            for f in self.ns.functions where f.name.lowercased().contains(currId.lowercased()) {
              arr.append(
                CompletionItem(
                  label: f.name,
                  kind: .function,
                  insertText: createTextForFunction(f),
                  insertTextFormat: .snippet
                )
              )
            }
            self.findMatchingIdentifiers(t, idexpr, &arr)
          }
          finalAttempt(prev, line, fp, md, &arr)
        }
        if prev.isEmpty || prev == ")" {
          if let t = self.tree, let md = t.metadata {
            self.subprojectGetVariableSpecialCase(fp, line, column, md, &arr)
            self.dependencySpecialCase(fp, line, column, md, prev, &arr)
            self.getOptionSpecialCase(t, fp, line, column, md, &arr)
            self.sourceFilesSpecialCase(t, fp, line, column, md, &arr)
          }
          if let t = self.tree, let md = t.metadata,
            let call = md.findFullMethodCallAt(fp, line, column),
            let al = call.argumentList as? ArgumentList
          {
            let usedKwargs: Set<String> = self.enumerateUsedKwargs(al)
            let s: Set<String> = self.fillKwargs(call)
            for c in s where !usedKwargs.contains(c) {
              arr.insert(
                CompletionItem(
                  label: c,
                  kind: .keyword,
                  insertText: "\(c): ${1:\(c)}",
                  insertTextFormat: .snippet
                ),
                at: 0
              )
            }
          } else if let t = self.tree, let md = t.metadata,
            let call = md.findFullFunctionCallAt(fp, line, column),
            let al = call.argumentList as? ArgumentList
          {
            let usedKwargs: Set<String> = self.enumerateUsedKwargs(al)
            let s: Set<String> = self.fillKwargs(call)
            for c in s where !usedKwargs.contains(c) {
              arr.insert(
                CompletionItem(
                  label: c,
                  kind: .keyword,
                  insertText: "\(c): ${1:\(c)}",
                  insertTextFormat: .snippet
                ),
                at: 0
              )
            }
          } else {
            for f in self.ns.functions {
              arr.append(
                CompletionItem(
                  label: f.name,
                  kind: .function,
                  insertText: createTextForFunction(f),
                  insertTextFormat: .snippet
                )
              )
            }
          }
        }
      } else {
        Self.LOG.error("Line out of bounds: \(line) > \(lines.count)")
      }
    }
    req.reply(CompletionList(isIncomplete: false, items: arr))
    Timing.INSTANCE.registerMeasurement(name: "complete", begin: begin, end: clock())
  }

  // swiftlint:enable cyclomatic_complexity

  private func extractErrorId(_ prev: String) -> String? {
    if prev.isEmpty { return nil }
    var ret = ""
    var idx = prev.count - 1
    while idx > 0 {
      idx -= 1
      let c = prev[idx]
      if c.isWhitespace {
        return ret
      } else if !(c.isLetter || c.isNumber || c == "_") {
        return ret
      }
      ret = "\(c)\(ret)"
    }
    return ret
  }

  // swiftlint:disable function_parameter_count
  private func dependencySpecialCase(
    _ fp: String,
    _ line: Int,
    _ column: Int,
    _ md: MesonMetadata,
    _ prev: String,
    _ arr: inout [CompletionItem]
  ) {
    if let fexpr = md.findFullFunctionCallAt(fp, line, column), let f = fexpr.function,
      f.id() == "dependency", let al = fexpr.argumentList as? ArgumentList, !al.args.isEmpty,
      al.args[0] is StringLiteral
    {
      Self.LOG.info("Found special call to dependency")
      let inLiteral = md.findStringLiteralAt(fp, line, column) != nil || prev.hasSuffix("'")
      for c in self.pkgNames {
        arr.append(
          CompletionItem(
            label: c,
            kind: .variable,
            insertText: inLiteral ? c : "'\(c)'",
            insertTextFormat: .snippet
          )
        )
      }
    }
  }

  private func sourceFilesSpecialCase(
    _ t: MesonTree,
    _ fp: String,
    _ line: Int,
    _ column: Int,
    _ md: MesonMetadata,
    _ arr: inout [CompletionItem]
  ) {
    if let fexpr = md.findFullFunctionCallAt(fp, line, column), let f = fexpr.function,
      self.isSourceFileFunction(f.id())
    {
      Self.LOG.info("Found special call to a function taking source files")
      var keys: [String] = []
      do {
        let children = try Path(fexpr.file.file).parent().children()
        for c in children {
          if c.isDirectory { continue }
          let ext = c.lastComponent.replacingOccurrences(
            of: c.lastComponentWithoutExtension,
            with: ""
          ).lowercased()
          if ext == ".c" || ext == ".cpp" || ext == ".vala" || ext == ".d" || ext == ".rs"
            || ext == ".h" || ext == ".hpp"
          {
            keys.append(c.lastComponent)
          }
        }
      } catch let e { Self.LOG.error("\(e)") }
      for c in keys {
        arr.append(
          CompletionItem(label: c, kind: .variable, insertText: c, insertTextFormat: .snippet)
        )
      }
    }
  }
  // swiftlint:enable function_parameter_count

  private func isSourceFileFunction(_ s: String) -> Bool {
    return s == "both_libraries" || s == "build_target" || s == "executable" || s == "files"
      || s == "jar" || s == "library" || s == "shared_library" || s == "static_library"
      || s == "shared_module"
  }

  // swiftlint:disable function_parameter_count
  private func getOptionSpecialCase(
    _ t: MesonTree,
    _ fp: String,
    _ line: Int,
    _ column: Int,
    _ md: MesonMetadata,
    _ arr: inout [CompletionItem]
  ) {
    if let fexpr = md.findFullFunctionCallAt(fp, line, column), let f = fexpr.function,
      f.id() == "get_option", let al = fexpr.argumentList as? ArgumentList, !al.args.isEmpty,
      al.args[0] is StringLiteral, let opts = t.options
    {
      Self.LOG.info("Found special call to get_option")
      for c in opts.opts.keys {
        arr.append(
          CompletionItem(label: c, kind: .variable, insertText: c, insertTextFormat: .snippet)
        )
      }
    }
  }
  // swiftlint:enable function_parameter_count

  private func subprojectGetVariableSpecialCase(
    _ fp: String,
    _ line: Int,
    _ column: Int,
    _ md: MesonMetadata,
    _ arr: inout [CompletionItem]
  ) {
    if let mexpr = md.findFullMethodCallAt(fp, line, column), let m = mexpr.method,
      m.id() == "subproject.get_variable", let al = mexpr.argumentList as? ArgumentList,
      !al.args.isEmpty, al.args[0] is StringLiteral,
      let subprojects = self.findSubproject(mexpr.obj.types), !subprojects.names.isEmpty,
      let ssT = self.subprojects
    {
      Self.LOG.info(
        "Found special call to subproject.get_variable for subprojects \(subprojects.names)"
      )
      var names: Set<String> = []
      for subproject in ssT.subprojects where subprojects.names.contains(subproject.name) {
        if let ast = subproject.tree, let sscope = ast.scope {
          sscope.variables.keys.forEach { names.insert($0) }
        }
      }
      for c in names {
        if c == "meson" || c == "build_machine" || c == "target_machine" || c == "host_machine" {
          continue
        }
        arr.append(
          CompletionItem(label: c, kind: .variable, insertText: c, insertTextFormat: .snippet)
        )
      }
    }
  }

  private func findSubproject(_ types: [Type]) -> MesonAST.Subproject? {
    return types.filter { $0 is MesonAST.Subproject }.map { $0 as! MesonAST.Subproject }.first
  }

  private func contains(_ node: Node, _ line: Int, _ column: Int) -> Bool {
    if node.location.startLine <= line && node.location.endLine >= line {
      if node.location.startColumn <= column && node.location.endColumn >= column { return true }
    }
    return false
  }

  private func findMatchingIdentifiers(
    _ t: MesonTree,
    _ idexpr: IdExpression,
    _ arr: inout [CompletionItem]
  ) {
    guard let mt = t.metadata else { return }
    guard let idexprs = mt.identifiers[idexpr.file.file] else { return }
    var other: [String] = []
    var idx = 0
    let mappedFile = self.mapper.fromSubprojectToCache(file: idexpr.file.file)
    for f in t.visitedFiles {
      if mappedFile == f {
        Self.LOG.info("Found file in visited files. Breaking...")
        break
      }
      other += t.foundVariables[idx]
      Self.LOG.info("Adding variables from \(f) to completion")
      idx += 1
    }
    let filtered =
      Array(
        idexprs.filter { $0.location.endLine < idexpr.location.startLine }.filter {
          ($0.parent is AssignmentStatement
            && ($0.parent as! AssignmentStatement).lhs.equals(right: $0))
            || ($0.parent is IterationStatement
              && ($0.parent as! IterationStatement).containsAsId($0))
        }.map { $0.id }
      ) + other
    let matching = Array(Set(filtered.filter { $0.lowercased().contains(idexpr.id.lowercased()) }))
    Self.LOG.info("findMatchingIdentifiers - Found matching identifiers: \(matching)")
    for m in matching + ["meson", "host_machine", "build_machine"] {
      arr.append(CompletionItem(label: m, kind: .variable, insertText: m, insertTextFormat: .plain))
    }
  }

  private func finalAttempt(
    _ prev: String,
    _ line: Int,
    _ fp: String,
    _ md: MesonMetadata,
    _ arr: inout [CompletionItem]
  ) {
    var n = prev.count - 1
    if n <= 0 { return }
    var invalid = false
    while prev[n] != "." && n >= 0 {
      Self.LOG.info("Finalcompletion: \(prev[0..<n])")
      if prev[n].isNumber || prev[n] == " " || prev[n] == "(" {
        invalid = true
        break
      }
      n -= 1
      if n == -1 {
        invalid = true
        break
      }
    }
    if invalid { return }
    let exprTypes = self.afterDotCompletion(md, fp, line, n)
    // The editor should filter this client side
    if let types = exprTypes {
      let s: Set<MesonAST.Method> = self.fillTypes(types)
      for c in s {
        arr.append(
          CompletionItem(
            label: c.name,
            kind: .method,
            insertText: createTextForFunction(c),
            insertTextFormat: .snippet
          )
        )
      }
    }
  }

  private func createTextForFunction(_ m: Function) -> String {
    var str = m.name + "("
    var n = 1
    for arg in m.args where arg is PositionalArgument {
      let p = (arg as! PositionalArgument)
      if !p.opt {
        str += "${\(n):\(p.name)}, "
        n += 1
      }
    }
    for arg in m.args where arg is Kwarg {
      let p = (arg as! Kwarg)
      if !p.opt {
        str += "\(p.name): ${\(n):\(p.name)}, "
        n += 1
      }
    }
    return (str + ")").replacingOccurrences(of: ", )", with: ")")
  }

  private func fillTypes(_ types: [Type]) -> Set<MesonAST.Method> {
    var s: Set<MesonAST.Method> = []
    for t in types {
      for m in self.ns.vtables[t.name]! {
        Self.LOG.info("Inserting completion: \(m.name)")
        s.insert(m)
      }
      if let t1 = t as? AbstractObject {
        var p = t1.parent
        while p != nil {
          for m in self.ns.vtables[p!.name]! {
            Self.LOG.info("Inserting completion: \(m.name)")
            s.insert(m)
          }
          p = p!.parent
        }
      }
    }
    return s
  }

  private func fillKwargs(_ callExpr: Node) -> Set<String> {
    var s: Set<String> = []
    if let fe = callExpr as? FunctionExpression, let f = fe.function {
      for arg in f.args where arg is Kwarg {
        Self.LOG.info("Adding kwarg to completion list: \((arg as! Kwarg).name)")
        s.insert((arg as! Kwarg).name)
      }
    } else if let me = callExpr as? MethodExpression, let m = me.method {
      for arg in m.args where arg is Kwarg {
        Self.LOG.info("Adding kwarg to completion list: \((arg as! Kwarg).name)")
        s.insert((arg as! Kwarg).name)
      }
    }
    return s
  }

  private func enumerateUsedKwargs(_ al: ArgumentList) -> Set<String> {
    var usedKwargs: Set<String> = []
    for arg in al.args where arg is KeywordItem {
      let kwi = (arg as! KeywordItem)
      let kwik = (kwi.key as! IdExpression)
      Self.LOG.info("Found already used kwarg: \(kwik.id)")
      usedKwargs.insert(kwik.id)
    }
    return usedKwargs
  }

  private func afterDotCompletion(
    _ md: MesonMetadata,
    _ fp: String,
    _ line: Int,
    _ column: Int,
    _ recurse: Bool = true
  ) -> [Type]? {
    Self.LOG.info("Starting afterDotCompletion: \(fp)[\(line):\(column)]")
    if let idexpr = md.findIdentifierAt(fp, line, column - 1) {
      Self.LOG.info("Found id expr: \(idexpr.id)")
      return idexpr.types
    } else if let fc = md.findFullFunctionCallAt(fp, line, column - 1), fc.function != nil {
      Self.LOG.info("Found function expr: \(fc.functionName())")
      return fc.types
    } else if let me = md.findFullMethodCallAt(fp, line, column - 1), me.method != nil {
      Self.LOG.info("Found method expr: \(me.method!.id())")
      return me.types
    } else if let aa = md.findFullArrayAccessAt(fp, line, column - 1) {
      Self.LOG.info("Found subscript expression")
      return aa.types
    } else if let sl = md.findStringLiteralAt(fp, line, column - 1) {
      return sl.types
    }
    if recurse && column > 0 {
      Self.LOG.info("afterDotCompletion - recursing")
      return self.afterDotCompletion(md, fp, line, column - 1, false)
    }
    Self.LOG.info("Ending afterDotCompletion without results")
    return nil
  }

  private func documentSymbol(_ req: Request<DocumentSymbolRequest>) {
    collectDocumentSymbols(self.findTree(req.params.textDocument.uri), req, self.mapper)
  }

  private func formatting(_ req: Request<DocumentFormattingRequest>) {
    let begin = clock()
    do {
      Self.LOG.info("Formatting \(req.params.textDocument.uri.fileURL!.path)")
      if let contents = self.getContents(file: req.params.textDocument.uri.fileURL!.path) {
        if let formatted = try formatFile(content: contents, params: req.params.options) {
          let newLines = formatted.split(whereSeparator: \.isNewline)
          let endOfLastLine = newLines.isEmpty ? 1024 : (newLines[newLines.count - 1].count)
          let range =
            Position(
              line: 0,
              utf16index: 0
            )..<Position(line: newLines.count + 2048, utf16index: endOfLastLine)
          let edit = TextEdit(range: range, newText: formatted)
          req.reply([edit])
          Timing.INSTANCE.registerMeasurement(name: "formatting", begin: begin, end: clock())
          if let sb = self.findSubprojectForUri(req.params.textDocument.uri),
            let csp = sb as? FolderSubproject
          {
            self.rebuildSubproject(csp)
          }
          return
        } else {
          Self.LOG.error("Unable to format file")
        }
      } else {
        Self.LOG.error("Unable to read file")
      }
    } catch {
      Self.LOG.error("Error formatting file \(error)")
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

  private func getContents(file: String) -> String? {
    if let sf = memfilesQueue.sync(execute: { self.memfiles[file] }) { return sf }
    Self.LOG.warning("Unable to find \(file) in memfiles")
    return try? String(contentsOfFile: file)
  }

  private func hover(_ req: Request<HoverRequest>) {
    collectHoverInformation(self.findTree(req.params.textDocument.uri), req, self.mapper, docs)
  }

  private func declaration(_ req: Request<DeclarationRequest>) {
    findDeclaration(self.findTree(req.params.textDocument.uri), req, self.mapper, Self.LOG)
  }

  private func definition(_ req: Request<DefinitionRequest>) {
    findDefinition(self.findTree(req.params.textDocument.uri), req, self.mapper, Self.LOG)
  }

  private func clearDiagnostics() { self.clearDiagnosticsForTree(tree: self.tree) }

  private func clearDiagnosticsForTree(tree: MesonTree?) {
    if tree != nil && tree!.metadata != nil {
      for k in tree!.metadata!.diagnostics.keys where tree!.metadata!.diagnostics[k] != nil {
        let arr: [Diagnostic] = []
        self.client.send(
          PublishDiagnosticsNotification(
            uri: DocumentURI(URL(fileURLWithPath: k)),
            diagnostics: arr
          )
        )
        tree!.metadata!.diagnostics.removeValue(forKey: k)
      }
    }
  }

  private func rebuildTree() {
    if self.parseTask != nil { self.parseTask!.cancel() }
    self.parseTask = Task {
      let beginSleep = clock()
      do {
        // 100 ms
        try await Task.sleep(nanoseconds: 100 * 1_000_000)
      } catch { Self.LOG.error("Error during sleeping: \(error)") }
      if Task.isCancelled {
        Self.LOG.info("Cancelling parsing - After sleeping")
        Timing.INSTANCE.registerMeasurement(
          name: "interruptedSleep",
          begin: beginSleep,
          end: clock()
        )
        return
      }
      let beginRebuilding = clock()
      self.clearDiagnostics()
      let endClearing = clock()
      Timing.INSTANCE.registerMeasurement(
        name: "clearingDiagnostics",
        begin: beginRebuilding,
        end: endClearing
      )
      if Task.isCancelled {
        Self.LOG.info("Cancelling parsing - After clearing diagnostics")
        return
      }
      let tmptree = MesonTree(
        file: self.path! + "/meson.build",
        ns: self.ns,
        dontCache: self.openFiles,
        cache: &self.astCache,
        memfiles: memfilesQueue.sync { self.memfiles }
      )
      let endParsingEntireTree = clock()
      Timing.INSTANCE.registerMeasurement(
        name: "parsingEntireTree",
        begin: endClearing,
        end: endParsingEntireTree
      )
      if Task.isCancelled {
        Self.LOG.info("Cancelling build - After building tree")
        return
      }
      tmptree.analyzeTypes(
        ns: self.ns,
        dontCache: self.openFiles,
        cache: &self.astCache,
        memfiles: memfilesQueue.sync { self.memfiles },
        subprojectState: self.subprojects,
        analysisOptions: self.analysisOptions
      )
      if Task.isCancelled {
        Self.LOG.info("Cancelling build - After analyzing types")
        return
      }
      let endAnalyzingTypes = clock()
      Timing.INSTANCE.registerMeasurement(
        name: "analyzingTypes",
        begin: endParsingEntireTree,
        end: endAnalyzingTypes
      )
      if tmptree.metadata == nil {
        let endRebuilding = clock()
        Timing.INSTANCE.registerMeasurement(
          name: "rebuildTree",
          begin: beginRebuilding,
          end: endRebuilding
        )
        return
      }
      if Task.isCancelled {
        Self.LOG.info("Cancelling build - Before sending diagnostics")
        return
      }
      self.sendNewDiagnostics(tmptree)
      let endSendingDiagnostics = clock()
      Timing.INSTANCE.registerMeasurement(
        name: "sendingDiagnostics",
        begin: endAnalyzingTypes,
        end: endSendingDiagnostics
      )
      Timing.INSTANCE.registerMeasurement(
        name: "rebuildTree",
        begin: beginRebuilding,
        end: endSendingDiagnostics
      )
      if Task.isCancelled {
        Self.LOG.info("Cancelling build - After sending diagnostics")
        self.clearDiagnosticsForTree(tree: tmptree)
        return
      }
      self.tree = tmptree
      self.parseTask = nil
    }
  }

  private func sendNewDiagnostics(_ tmptree: MesonTree?) {
    guard let tmptree = tmptree else { return }
    if tmptree.metadata == nil { return }
    for k in tmptree.metadata!.diagnostics.keys where tmptree.metadata!.diagnostics[k] != nil {
      var arr: [Diagnostic] = []
      let diags = tmptree.metadata!.diagnostics[k]!
      Self.LOG.info("Publishing \(diags.count) diagnostics for \(k)")
      for diag in diags {
        if diag.severity == .error {
          Self.LOG.error("\(diag.message)")
        } else {
          Self.LOG.warning("\(diag.message)")
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
        PublishDiagnosticsNotification(uri: DocumentURI(URL(fileURLWithPath: k)), diagnostics: arr)
      )
    }
  }

  private func rebuildSubproject(_ sb: MesonAnalyze.Subproject) {
    if let fsp = sb as? FolderSubproject {
      if let t = tasks[fsp.realpath] { t.cancel() }
      var cache = self.astCaches[fsp.realpath]!
      cache.removeAll()
      tasks[fsp.realpath] = Task {
        // It should be cached theoretically, but
        // the caching seems to go wrong.
        self.clearDiagnosticsForTree(tree: fsp.tree)
        if Task.isCancelled { return }
        Self.LOG.info("Starting task")
        var astCacheTemp: [String: Node] = [:]
        let files = self.openSubprojectFiles[fsp.realpath]
        fsp.parse(
          ns,
          dontCache: files ?? [],
          cache: &astCacheTemp,
          memfiles: memfilesQueue.sync { self.memfiles },
          analysisOptions: self.analysisOptions
        )
        var sendDiags = self.otherSettings.ignoreDiagnosticsFromSubprojects == nil
        if let idfs = self.otherSettings.ignoreDiagnosticsFromSubprojects {
          if idfs.isEmpty { sendDiags = false } else { sendDiags = !idfs.contains(sb.name) }
        }
        if !Task.isCancelled && sendDiags { self.sendNewDiagnostics(fsp.tree) }
        if Task.isCancelled || !sendDiags { self.clearDiagnosticsForTree(tree: fsp.tree) }
        Self.LOG.info("Task ended, cancelled: \(Task.isCancelled)")
      }
    } else {
      Self.LOG.error("Unable to rebuild subproject as it is not folder based!")
    }
  }

  private func openDocument(_ note: Notification<DidOpenTextDocumentNotification>) {
    if let sb = self.findSubprojectForUri(note.params.textDocument.uri) {
      if sb is FolderSubproject {
        let file = note.params.textDocument.uri.fileURL?.path
        Self.LOG.info("[Open] \(file!) in subproject \(sb.realpath)")
        if !self.openSubprojectFiles.keys.contains(sb.realpath) {
          self.openSubprojectFiles[sb.realpath] = []
        }
        var s = self.openSubprojectFiles[sb.realpath]!
        s.insert(file!)
        self.openSubprojectFiles[sb.realpath] = s
        if var ac = self.astCaches[sb.realpath] { ac.removeValue(forKey: file!) }
      }
    } else {
      let file = note.params.textDocument.uri.fileURL?.path
      self.openFiles.insert(file!)
      self.astCache.removeValue(forKey: file!)
    }
  }

  private func didSaveDocument(_ note: Notification<DidSaveTextDocumentNotification>) {
    if let sb = self.findSubprojectForUri(note.params.textDocument.uri) {
      if sb is FolderSubproject {
        let file = note.params.textDocument.uri.fileURL?.path
        Self.LOG.info("[Save] \(file!) in subproject \(sb.realpath)")
        _ = memfilesQueue.sync { self.memfiles.removeValue(forKey: file!) }
        self.rebuildSubproject(sb)
      }
    } else {
      let file = note.params.textDocument.uri.fileURL?.path
      // Either the saves were changed or dropped, so use the contents
      // of the file
      Self.LOG.info("[Save] Dropping \(file!) from memcache")
      _ = memfilesQueue.sync { self.memfiles.removeValue(forKey: file!) }
      self.rebuildTree()
    }
  }

  private func closeDocument(_ note: Notification<DidCloseTextDocumentNotification>) {
    if let sb = self.findSubprojectForUri(note.params.textDocument.uri) {
      if sb is FolderSubproject {
        let file = note.params.textDocument.uri.fileURL?.path
        Self.LOG.info("[Close] \(file!) in subproject \(sb.realpath)")
        Self.LOG.info("\(self.openSubprojectFiles.keys)")
        if var s = self.openSubprojectFiles[sb.realpath] {
          s.remove(file!)
          self.openSubprojectFiles[sb.realpath] = s
        }
        _ = memfilesQueue.sync { self.memfiles.removeValue(forKey: file!) }
        self.rebuildSubproject(sb)
      }
    } else {
      let file = note.params.textDocument.uri.fileURL?.path
      // Either the saves were changed or dropped, so use the contents
      // of the file
      Self.LOG.info("[Close] Dropping \(file!) from memcache")
      self.openFiles.remove(file!)
      _ = memfilesQueue.sync { self.memfiles.removeValue(forKey: file!) }
      self.rebuildTree()
    }
  }

  private func changeDocument(_ note: Notification<DidChangeTextDocumentNotification>) {
    if let sb = self.findSubprojectForUri(note.params.textDocument.uri) {
      if sb is FolderSubproject {
        let file = note.params.textDocument.uri.fileURL?.path
        Self.LOG.info("[Change] \(file!) in subproject \(sb.realpath)")
        memfilesQueue.sync { self.memfiles[file!] = note.params.contentChanges[0].text }
        self.rebuildSubproject(sb)
      }
    } else {
      let file = note.params.textDocument.uri.fileURL?.path
      Self.LOG.info("[Change] Adding \(file!) to memcache")
      memfilesQueue.sync { self.memfiles[file!] = note.params.contentChanges[0].text }
      self.rebuildTree()
    }
  }

  private func didCreateFiles(_ note: Notification<DidCreateFilesNotification>) {
    self.rebuildTree()
  }
  // swiftlint:disable cyclomatic_complexity
  private func parseOptions(settings: LSPAny) {
    // swiftlint:disable force_try
    let dict = try! settings.asDictionary()
    // swiftlint:enable force_try
    if let others = dict["others"] as? [String: Any] {
      var ignoreDiagnosticsFromSubprojects: [String]?
      var neverDownloadAutomatically = false
      if let ignore = others["ignoreDiagnosticsFromSubprojects"] as? Bool {
        ignoreDiagnosticsFromSubprojects = ignore ? [] : nil
      } else if let ignore = others["ignoreDiagnosticsFromSubprojects"] as? [Any] {
        ignoreDiagnosticsFromSubprojects = Array(
          ignore.filter { $0 as? String != nil }.map { $0 as! String }
        )
      }
      if let neverDownload = others["neverDownloadAutomatically"] as? Bool {
        neverDownloadAutomatically = neverDownload
      }
      self.otherSettings = OtherSettings(
        ignoreDiagnosticsFromSubprojects: ignoreDiagnosticsFromSubprojects,
        neverDownloadAutomatically: neverDownloadAutomatically
      )
    }
    if let lintings = dict["linting"] as? [String: Any] {
      var disableNameLinting = false
      var disableAllIdLinting = false
      var disableCompilerIdLinting = false
      var disableCompilerArgumentIdLinting = false
      var disableLinkerIdLinting = false
      var disableCpuFamilyLinting = false
      var disableOsFamilyLinting = false
      if let d = lintings["disableNameLinting"] as? Bool { disableNameLinting = d }
      if let d = lintings["disableAllIdLinting"] as? Bool { disableAllIdLinting = d }
      if let d = lintings["disableCompilerIdLinting"] as? Bool { disableCompilerIdLinting = d }
      if let d = lintings["disableCompilerArgumentIdLinting"] as? Bool {
        disableCompilerArgumentIdLinting = d
      }
      if let d = lintings["disableLinkerIdLinting"] as? Bool { disableLinkerIdLinting = d }
      if let d = lintings["disableCpuFamilyLinting"] as? Bool { disableCpuFamilyLinting = d }
      if let d = lintings["disableOsFamilyLinting"] as? Bool { disableOsFamilyLinting = d }
      self.analysisOptions = AnalysisOptions(
        disableNameLinting: disableNameLinting,
        disableAllIdLinting: disableAllIdLinting,
        disableCompilerIdLinting: disableCompilerIdLinting,
        disableCompilerArgumentIdLinting: disableCompilerArgumentIdLinting,
        disableLinkerIdLinting: disableLinkerIdLinting,
        disableCpuFamilyLinting: disableCpuFamilyLinting,
        disableOsFamilyLinting: disableOsFamilyLinting
      )
    }
    self.tasks.values.forEach { $0.cancel() }
    self.parseTask?.cancel()
    if let t = self.parseSubprojectTask { t.cancel() }
    self.parseSubprojectTask = Task.detached {
      self.subprojects = nil
      await self.setupSubprojects()
    }
    self.rebuildTree()
  }
  // swiftlint:enable cyclomatic_complexity

  private func didChangeConfiguration(_ note: Notification<DidChangeConfigurationNotification>) {
    let config = note.params.settings
    if case .unknown(let settings) = config { self.parseOptions(settings: settings) }
  }

  private func didDeleteFiles(_ note: Notification<DidDeleteFilesNotification>) {
    for f in note.params.files {
      let path = f.uri.fileURL!.path
      if memfilesQueue.sync(execute: { self.memfiles[path] }) != nil {
        _ = memfilesQueue.sync { self.memfiles.removeValue(forKey: path) }
      }
      if self.openFiles.contains(path) { self.openFiles.remove(path) }
      if self.astCache[path] != nil { self.astCache.removeValue(forKey: path) }
    }
    self.rebuildTree()
  }

  private func capabilities(_ supportsRenaming: Bool) -> ServerCapabilities {
    let legend = SemanticTokensLegend(
      tokenTypes: [
        "substitute", "substitute_bounds", "variable", "function", "method", "keyword", "string",
        "number",
      ],
      tokenModifiers: ["readonly", "defaultLibrary"]
    )
    return ServerCapabilities(
      textDocumentSync: .options(
        TextDocumentSyncOptions(openClose: true, change: .full, save: .bool(true))
      ),
      hoverProvider: .bool(true),
      completionProvider: .some(
        CompletionOptions(resolveProvider: false, triggerCharacters: [".", "_"])
      ),
      definitionProvider: .bool(true),
      documentHighlightProvider: .bool(true),
      documentSymbolProvider: .bool(true),
      workspaceSymbolProvider: .bool(true),
      codeActionProvider: .bool(true),
      documentFormattingProvider: .bool(true),
      renameProvider: .bool(supportsRenaming),
      declarationProvider: .bool(true),
      workspace: WorkspaceServerCapabilities(),
      semanticTokensProvider: SemanticTokensOptions(
        legend: legend,
        range: .bool(false),
        full: .value(SemanticTokensOptions.SemanticTokensFullOptions(delta: false))
      ),
      inlayHintProvider: .bool(true)
    )
  }

  private func onProgress(_ msg: String) {
    if self.token == nil { return }
    let progressMessage = WorkDoneProgress(
      token: self.token!,
      value: WorkDoneProgressKind.report(
        WorkDoneProgressReport(message: "Parsing subproject", percentage: 0)
      )
    )
    self.client.send(progressMessage)
  }

  private func getDirectoryModificationTime(path: String) -> Date? {
    do {
      let fileManager = FileManager.default
      let attributes = try fileManager.attributesOfItem(atPath: path)
      return attributes[.modificationDate] as? Date
    } catch {
      if Path(path).exists { Self.LOG.error("Error: \(error)") }
      return nil
    }
  }

  // swiftlint:disable cyclomatic_complexity
  private func setupSubprojects() async {
    let t = ProgressToken.string(UUID().uuidString)
    self.token = t
    let old = self.subprojects
    let workDoneCreate = CreateWorkDoneProgressRequest(token: t)
    do { _ = try self.client.sendSync(workDoneCreate) } catch let err { Self.LOG.error("\(err)") }
    let beginMessage = WorkDoneProgress(
      token: t,
      value: WorkDoneProgressKind.begin(
        WorkDoneProgressBegin(title: "Querying subprojects", percentage: 0)
      )
    )
    self.client.send(beginMessage)
    if Task.isCancelled {
      let endMessage = WorkDoneProgress(
        token: t,
        value: WorkDoneProgressKind.end(WorkDoneProgressEnd())
      )
      self.client.send(endMessage)
      self.token = nil
      return
    }
    do {
      self.subprojects = try SubprojectState(rootDir: self.path!, onProgress: onProgress)
      self.subprojectsDirectoryMtime = self.getDirectoryModificationTime(
        path: self.path! + "\(Path.separator)subprojects"
      )
      if Task.isCancelled {
        let endMessage = WorkDoneProgress(
          token: t,
          value: WorkDoneProgressKind.end(WorkDoneProgressEnd())
        )
        self.client.send(endMessage)
        self.token = nil
        self.subprojects = old
        return
      }
      if let date = self.subprojectsDirectoryMtime {
        Self.LOG.info("subprojects/ directory was modified \(date)")
      }
    } catch let error {
      Self.LOG.error("\(error)")
      let endMessage = WorkDoneProgress(
        token: t,
        value: WorkDoneProgressKind.end(WorkDoneProgressEnd())
      )
      self.client.send(endMessage)
      self.subprojects = old
      return
    }
    if self.subprojects == nil { return }
    for err in self.subprojects!.errors {
      Self.LOG.error("Got error during setting up subprojects: \(err)")
    }
    Self.LOG.info("Setup all directories for subprojects")
    if self.subprojects == nil { return }
    let count = Double(self.subprojects!.subprojects.count)
    var n = 0
    if self.subprojects == nil { return }
    for sp in self.subprojects!.subprojects {
      let percentage = Int((Double(n + 1) / count) * 100)
      let progressMessage = WorkDoneProgress(
        token: t,
        value: WorkDoneProgressKind.report(
          WorkDoneProgressReport(message: "Parsing subproject \(sp.name)", percentage: percentage)
        )
      )
      self.client.send(progressMessage)
      var cache: [String: Node] = [:]
      sp.parse(
        self.ns,
        dontCache: [],
        cache: &cache,
        memfiles: memfilesQueue.sync { self.memfiles },
        analysisOptions: analysisOptions
      )
      var sendDiags = self.otherSettings.ignoreDiagnosticsFromSubprojects == nil
      if let idfs = self.otherSettings.ignoreDiagnosticsFromSubprojects {
        if idfs.isEmpty { sendDiags = false } else { sendDiags = !idfs.contains(sp.name) }
      }
      if sendDiags {
        self.sendNewDiagnostics(sp.tree)
      } else {
        self.clearDiagnosticsForTree(tree: sp.tree)
      }
      self.astCaches[sp.realpath] = cache
      n += 1
    }
    if self.subprojects == nil { return }
    self.mapper.subprojects = self.subprojects!
    Self.LOG.info("Setup all subprojects, rebuilding tree (If there were any found)")
    if self.subprojects == nil { return }
    if !self.subprojects!.subprojects.isEmpty {
      if self.parseTask != nil {
        do { try await self.parseTask!.value } catch let err { Self.LOG.info("\(err)") }
      }
      self.rebuildTree()
    }
    let endMessage = WorkDoneProgress(
      token: t,
      value: WorkDoneProgressKind.end(WorkDoneProgressEnd())
    )
    self.client.send(endMessage)
    self.token = nil
    if Task.isCancelled {
      self.subprojects = old
      return
    }
    await self.updateSubprojects()
    self.queue.asyncAfter(deadline: .now() + mtimeChecker) {
      self.checkMtime()
      self.scheduleNextMtimeCheck()
    }
  }
  // swiftlint:enable cyclomatic_complexity

  private func updateSubprojects() async {
    let t = ProgressToken.string(UUID().uuidString)
    self.token = t
    let workDoneCreate = CreateWorkDoneProgressRequest(token: t)
    do { _ = try self.client.sendSync(workDoneCreate) } catch let err { Self.LOG.error("\(err)") }
    let beginMessage = WorkDoneProgress(
      token: t,
      value: WorkDoneProgressKind.begin(
        WorkDoneProgressBegin(title: "Updating subprojects", percentage: 0)
      )
    )
    self.client.send(beginMessage)
    if self.subprojects == nil { return }
    let count = Double(self.subprojects!.subprojects.count)
    var n = 0
    if self.subprojects == nil { return }
    for s in self.subprojects!.subprojects {
      n += 1
      let percentage = Int((Double(n + 1) / count) * 100)
      let progressMessage = WorkDoneProgress(
        token: t,
        value: WorkDoneProgressKind.report(
          WorkDoneProgressReport(message: "Updating subproject \(s.name)", percentage: percentage)
        )
      )
      self.client.send(progressMessage)
      do {
        try s.update()
        if Task.isCancelled {
          let endMessage = WorkDoneProgress(
            token: t,
            value: WorkDoneProgressKind.end(WorkDoneProgressEnd())
          )
          self.client.send(endMessage)
          self.token = nil
          return
        }
        var cache: [String: Node] = [:]
        let dontCache: Set<String> =
          (s is FolderSubproject)
          ? (self.openSubprojectFiles[(s as! FolderSubproject).realpath] ?? []) : []
        s.parse(
          self.ns,
          dontCache: dontCache,
          cache: &cache,
          memfiles: memfilesQueue.sync { self.memfiles },
          analysisOptions: self.analysisOptions
        )
        var sendDiags = self.otherSettings.ignoreDiagnosticsFromSubprojects == nil
        if let idfs = self.otherSettings.ignoreDiagnosticsFromSubprojects {
          if idfs.isEmpty { sendDiags = false } else { sendDiags = !idfs.contains(s.name) }
        }
        if sendDiags {
          self.sendNewDiagnostics(s.tree)
        } else {
          self.clearDiagnosticsForTree(tree: s.tree)
        }
        self.astCaches[s.realpath] = cache
      } catch let err { Self.LOG.info("\(err)") }
    }
    if self.subprojects == nil { return }
    if !self.subprojects!.subprojects.isEmpty {
      if self.parseTask != nil {
        do { try await self.parseTask!.value } catch let err { Self.LOG.info("\(err)") }
      }
      self.rebuildTree()
    }
    let endMessage = WorkDoneProgress(
      token: t,
      value: WorkDoneProgressKind.end(WorkDoneProgressEnd())
    )
    self.client.send(endMessage)
    self.token = nil
  }

  private func initialize(_ req: Request<InitializeRequest>) {
    let p = req.params
    var supportsRenaming = false
    if let clientInfo = p.clientInfo {
      Self.LOG.info("Connected with client \(clientInfo.name) \(clientInfo.version ?? "Unknown")")
      if p.clientInfo!.name == "gnome-builder" { supportsRenaming = true }
    }
    if !supportsRenaming {
      Self.LOG.info(
        "Renaming is disabled as it is broken outside of GNOME Builder. Use GNOME Builder for an optimal experience."
      )
    }
    if p.rootPath == nil { fatalError("Nothing else supported other than using rootPath") }
    self.path = p.rootPath
    self.mapper.rootDir = self.path!
    if let settings = p.initializationOptions {
      self.parseOptions(settings: settings)
    } else {
      self.parseSubprojectTask = Task { await self.setupSubprojects() }
      self.rebuildTree()
    }
    req.reply(InitializeResult(capabilities: self.capabilities(supportsRenaming)))
    Self.LOG.info(
      "Swift-MesonLSP is licensed under the terms of the GNU General Public License v3.0"
    )
    Self.LOG.info(
      "Need help? - Open a discussion here: https://github.com/JCWasmx86/Swift-MesonLSP/discussions or join https://matrix.to/#/#mesonlsp:matrix.org"
    )
  }

  private func clientInitialized(_: Notification<InitializedNotification>) {
    // Nothing to do.
  }

  private func cancelRequest(_ notification: Notification<CancelRequestNotification>) {
    // No cancellation for anything supported (yet?)
  }

  private func shutdown(_ request: Request<ShutdownRequest>) {
    self.prepareForExit()
    #if !os(Windows)
      self.server.stop()
    #endif
    request.reply(VoidResponse())
  }

  private func exit(_ notification: Notification<ExitNotification>) {
    self.prepareForExit()
    self.onExit()
  }

  #if !os(Windows)
    #if os(Linux)
      private func generateStatsHTML() -> String {
        if self.stats.isEmpty || self.stats["notifications"]!.isEmpty {
          return "Please wait a bit!"
        }
        let rows = self.stats["notifications"]!.map { $0.0 }
        var x: [Int] = []
        var n = 0
        for _ in rows.reversed() {
          x.append(-n)
          n += 1
        }
        let nNotifications = self.stats["notifications"]!.map { $0.1 }
        let nRequests = self.stats["requests"]!.map { $0.1 }
        let memoryUsage = self.stats["memory_usage"]!.map { Double($0.1) / (1024 * 1024) }
        var s = ""
        for n in Array(self.notifications.keys) + Array(self.requests.keys) {
          if self.stats[n] == nil { continue }
          s += "ctx = document.getElementById(\"chart\(n.hash)\");"
          s += """
            	new Chart(ctx, {
            		type: "line",
            		data: {
                  labels: tags,
                  datasets: [
                    {
                        label: "Number of requests to `\(n)`",
                        data: [@1@],
                        borderColor: "#1c71d8",
                    },
                    {
                        label: "Memory usage in MB",
                        data: [@2@],
                        borderColor: "#613583",
                    },
                  ],
            		},
            	});
            """
          var nn = Array(self.stats[n]!.reversed().map { $0.1 })
          while nn.count < x.count { nn.append(0) }
          var mm = Array(memoryUsage.reversed()[0..<nn.count].reversed())
          while mm.count < x.count { mm.append(0) }
          s = s.replacingOccurrences(
            of: "@1@",
            with: nn.reversed().map { String($0) }.joined(separator: ", ")
          )
          s = s.replacingOccurrences(of: "@2@", with: mm.map { String($0) }.joined(separator: ", "))
        }
        var htmln = ""
        for n in self.notifications.keys {
          if self.stats[n] == nil { continue }
          htmln +=
            "<h3>\(n)</h3>\n<div style=\"position: relative; height:40vh; width:80vw\"><canvas id=\"chart\(n.hash)\" width=\"400\" height=\"300\"></canvas></div>\n"
        }
        var htmlr = ""
        for n in self.requests.keys {
          if self.stats[n] == nil { continue }
          htmlr +=
            "<h3>\(n)</h3>\n<div style=\"position: relative; height:40vh; width:80vw\"><canvas id=\"chart\(n.hash)\" width=\"400\" height=\"300\"></canvas></div>\n"
        }
        let html = """
          <!DOCTYPE html>
          <html>
          <head>
          	<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
          </head>
          <body>
            <h1>General</h1>
          	<div><canvas id="chart"></canvas></div>
          	<h2>Notifications</h2>
            \(htmln)
          	<h2>Requests</h2>
            \(htmlr)
          	<script>
          	const tags = [@0@];
          	let ctx = document.getElementById("chart");
          	new Chart(ctx, {
          		type: "line",
          		data: {
          			labels: tags,
          			datasets: [
          				{
          				  label: "Number of notifications",
          				  data: [@1@],
          				  borderColor: "#1c71d8",
          				},
          				{
          				  label: "Number of requests",
          				  data: [@2@],
          				  borderColor: "#c01c28",
          				},
          				{
          				  label: "Memory usage in MB",
          				  data: [@3@],
          				  borderColor: "#613583",
          				},
          			],
          		},
          	});
            \(s)
          	</script>
          </body>
          </html>
          """
        return html.replacingOccurrences(
          of: "@0@",
          with: x.reversed().map { String($0) }.joined(separator: ", ")
        ).replacingOccurrences(
          of: "@1@",
          with: nNotifications.map { String($0) }.joined(separator: ", ")
        ).replacingOccurrences(
          of: "@2@",
          with: nRequests.map { String($0) }.joined(separator: ", ")
        ).replacingOccurrences(
          of: "@3@",
          with: memoryUsage.map { String($0) }.joined(separator: ", ")
        )
      }
    #endif
    private func generateCountHTML() -> String {
      let header = """
        	<!DOCTYPE html>
        	<html>
        	<head>
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
        """
      var body = ""
      if let t = self.tree, let ast = t.ast {
        let visitor = NodeCounter()
        ast.visit(visitor: visitor)
        body = """
          <h1>Main project</h1>
          <table>
          	<tr>
          		<th>Type</th>
          		<th>Count</th>
          	</tr>
          """
        for k in visitor.nodeCount { body += "<tr><td>\(k.0)</td><td>\(k.1)</td></tr>" }
        body += "</table>"
      }
      if let sb = self.subprojects, !sb.subprojects.isEmpty {
        body += "<h2>Subprojects</h2>"
        for b in sb.subprojects where b.tree != nil && b.tree!.ast != nil {
          body += "<h3>\(b.description)</h3>"
          body += """
            	<table>
            	<tr>
            		<th>Type</th>
            		<th>Count</th>
            	</tr>
            """
          let visitor = NodeCounter()
          b.tree?.ast?.visit(visitor: visitor)
          for k in visitor.nodeCount { body += "<tr><td>\(k.0)</td><td>\(k.1)</td></tr>" }
          body += "</table>"
        }
      }
      body += "</body>"
      return header + body
    }

    private func isAvailable(_ command: String) -> String {
      let task = Process()
      task.arguments = ["-c", "which \(command)"]
      task.executableURL = URL(fileURLWithPath: "/bin/sh")
      do { try task.run() } catch { return "🔴" }
      task.waitUntilExit()
      if task.terminationStatus != 0 { return "🔴" }
      return "🟢"
    }

    private func generateStatusHTML() -> String {
      let header = """
        	<!DOCTYPE html>
        	<html>
        	<head>
        	<meta charset="utf-8">
        	<title>Status for Swift-MesonLSP</title>
        	</head>
        	<body>
        """
      var body =
        "<h2>Available commands</h2> muon is required for formatting, patch/git is used for applying patches to wraps; "
      body +=
        "Additionally, git is used for git wraps. Svn/Hg are used for wraps, too. wget or curl are used for downloading file wraps and patches for all wraps<ul>"
      let commands = ["muon", "patch", "git", "svn", "hg", "wget", "curl"]
      for c in commands { body += "<li>\(self.isAvailable(c)) \(c)</li>" }
      body += "<ul></body></html>"
      return header + body
    }

    private func generateCacheHTML() -> String {
      let header = """
        	<!DOCTYPE html>
        	<html>
        	<head>
        	<meta http-equiv="refresh" content="5" />
        	</head>
        	<body>
          <h1>Mainproject</h1>
        	<h2>Open files</h2>
        	<ul>
        """
      var body = ""
      for o in self.openFiles { body += "<li>\(o)</li>\n" }
      body += "</ul>\n"
      body += "<h2>Cached ASTs</h2>\n<ul>\n"
      for o in self.astCache.keys { body += "<li>\(o)</li>\n" }
      body += "</ul>\n"
      if self.subprojects != nil {
        body += "<h1>Subprojects</h1>"
        for s in self.subprojects!.subprojects {
          body += "<h2>\(s.realpath)</h2>\n"
          body += "<h3>Open files</h3>\n<ul>"
          if let ac = self.openSubprojectFiles[s.realpath] {
            for k in ac { body += "<li>\(k)</li>\n" }
          }
          body += "</ul><h3>Cached ASTs</h3>\n<ul>"
          if let ac = self.astCaches[s.realpath] { for k in ac.keys { body += "<li>\(k)</li>\n" } }
          body += "</ul>"
        }
      }
      body += "</body></html>"
      return header + body
    }

    private func generateHTML() -> String {
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
        let rounding = 2
        str.append(
          "<tr>" + "<td>\(t.name)</td>" + "<td>\(t.hits())</td>"
            + "<td>\(t.min().round(to: rounding))</td>" + "<td>\(t.max().round(to: rounding))</td>"
            + "<td>\(t.median().round(to: rounding))</td>"
            + "<td>\(t.average().round(to: rounding))</td>"
            + "<td>\(t.stddev().round(to: rounding))</td>"
            + "<td>\(t.sum().round(to: rounding))</td></tr>"
        )
      }
      let footer = """
        	</table>

        	</body>
        	</html>
        """
      return header + str + footer
    }
  #endif
}

extension Double {
  func round(to places: Int) -> Double {
    let base = 10
    let divisor = pow(Double(base), Double(places))
    return (self * divisor).rounded() / divisor
  }
}

extension String {
  subscript(offset: Int) -> Character { return self[index(startIndex, offsetBy: offset)] }
  subscript(_ range: CountableRange<Int>) -> String {
    let start = index(startIndex, offsetBy: max(0, range.lowerBound))
    let end = index(
      start,
      offsetBy: min(self.count - range.lowerBound, range.upperBound - range.lowerBound)
    )
    return String(self[start..<end])
  }

  subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
    let start = index(startIndex, offsetBy: max(0, range.lowerBound))
    return String(self[start...])
  }
}

class OtherSettings {
  public let ignoreDiagnosticsFromSubprojects: [String]?
  public let neverDownloadAutomatically: Bool

  public init(ignoreDiagnosticsFromSubprojects: [String]?, neverDownloadAutomatically: Bool) {
    self.ignoreDiagnosticsFromSubprojects = ignoreDiagnosticsFromSubprojects
    self.neverDownloadAutomatically = neverDownloadAutomatically
  }
}

extension Encodable {
  func asDictionary() throws -> [String: Any] {
    let data = try JSONEncoder().encode(self)
    guard
      let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        as? [String: Any]
    else { fatalError("Why????") }
    return dictionary
  }
}
