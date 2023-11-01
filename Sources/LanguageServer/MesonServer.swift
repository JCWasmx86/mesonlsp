import Dispatch
import Foundation
import IOUtils
import LanguageServerProtocol
import Logging
import LSPLogging
import MesonAnalyze
import MesonAST
import MesonDocs
import Timing
import Wrap
// There seem to be some name collisions
public typealias MesonVoid = ()

public final actor MesonServer: MessageHandler {
  static let LOG = Logger(label: "LanguageServer::MesonServer")
  static let MIN_PORT = 65000
  static let MAX_PORT = 65550
  var memfilesQueue = DispatchQueue(label: "mesonserver.memfiles")
  private let messageHandlingQueue = AsyncQueue<TaskMetadata>()
  private let cancellationMessageHandlingQueue = AsyncQueue<Serial>()
  private let notificationIDForLoggingLock = NSLock()
  private var notificationIDForLogging: Int = 0
  var onExit: () -> MesonVoid
  var path: String?
  var tree: MesonTree?
  var ns: TypeNamespace
  var memfiles: [String: String] = [:]
  var parseSubprojectTask: Task<(), Error>?
  var parseTask: Task<(), Error>?
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
    neverDownloadAutomatically: false,
    disableInlayHints: false,
    muonPath: nil
  )
  let client: Connection
  var notificationCount: UInt64 = 0
  var requestCount: UInt64 = 0
  internal var notifications: [String: UInt] = [:]
  internal var requests: [String: UInt] = [:]
  public let queue: DispatchQueue = DispatchQueue(
    label: "language-server-queue",
    qos: .userInitiated
  )

  public init(client: Connection, onExit: @escaping () -> MesonVoid) {
    self.onExit = onExit
    self.ns = TypeNamespace()
    self.client = client
    Task.detached {
      do { try await WrapDB.INSTANCE.initDB() } catch {
        Self.LOG.error("Failed to init WrapDB: \(error)")
      }
    }
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
      Task {
        for str in output!.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline) {
          await self.insertPkgName(String(str))
        }
      }
    } catch { Self.LOG.error("\(error)") }
  }

  private func insertPkgName(_ str: String) async { self.pkgNames.insert(str) }

  private func setSubprojects(_ subprojects: SubprojectState?) async {
    self.subprojects = subprojects
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
            await self.setSubprojects(nil)
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
      Task {
        await self.checkMtime()
        await self.scheduleNextMtimeCheck()
      }
    }
  }

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

  private func semanticTokenFull(_ req: DocumentSemanticTokensRequest) async throws
    -> DocumentSemanticTokensResponse
  {
    let begin = clock()
    let file = mapper.fromSubprojectToCache(file: req.textDocument.uri.fileURL!.path)
    if let t = self.findTree(req.textDocument.uri), let mt = t.findSubdirTree(file: file),
      let ast = mt.ast
    {
      let stv = SemanticTokenVisitor()
      ast.visit(visitor: stv)
      Timing.INSTANCE.registerMeasurement(name: "semanticTokens", begin: begin, end: clock())
      return DocumentSemanticTokensResponse(data: stv.finish())
    }
    Timing.INSTANCE.registerMeasurement(name: "semanticTokens", begin: begin, end: clock())
    return DocumentSemanticTokensResponse(data: [])
  }

  private func foldingRanges(_ req: FoldingRangeRequest) async throws -> [FoldingRange] {
    let begin = clock()
    let file = mapper.fromSubprojectToCache(file: req.textDocument.uri.fileURL!.path)
    if let t = self.findTree(req.textDocument.uri), let mt = t.findSubdirTree(file: file),
      let ast = mt.ast
    {
      let stv = FoldingRangeVisitor()
      ast.visit(visitor: stv)
      Timing.INSTANCE.registerMeasurement(name: "foldingRanges", begin: begin, end: clock())
      return stv.ranges
    }
    Timing.INSTANCE.registerMeasurement(name: "foldingRanges", begin: begin, end: clock())
    return []
  }

  private func rename(_ req: RenameRequest) async throws -> WorkspaceEdit {
    let params = req
    guard let t = self.tree else {
      throw ResponseError(code: .requestFailed, message: "No tree available!")
    }
    guard
      let id = t.metadata?.findIdentifierAt(
        params.textDocument.uri.fileURL!.absoluteURL.path,
        params.position.line,
        params.position.utf16index
      )
    else {
      throw ResponseError(code: .requestFailed, message: "No identifier found at this location!")
    }
    if let parentLoop = id.parent as? IterationStatement, parentLoop.containsAsId(id) {
      let lvr = LoopVariableRename(id.id, params.newName, t)
      parentLoop.visit(visitor: lvr)
      return WorkspaceEdit(changes: lvr.edits)
    }
    if let kw = id.parent as? KeywordItem, kw.key.equals(right: id) {
      return WorkspaceEdit(changes: [:])
    }
    if let fn = id.parent as? FunctionExpression, fn.id.equals(right: id) {
      return WorkspaceEdit(changes: [:])
    }
    if let fn = id.parent as? MethodExpression, fn.id.equals(right: id) {
      return WorkspaceEdit(changes: [:])
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
    return WorkspaceEdit(changes: edits)
  }

  private func codeActions(_ req: CodeActionRequest) async throws -> CodeActionRequestResponse? {
    let begin = clock()
    let uri = req.textDocument.uri
    let range = req.range
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
    Timing.INSTANCE.registerMeasurement(name: "codeaction", begin: begin, end: clock())
    return CodeActionRequestResponse(
      codeActions: actions,
      clientCapabilities: TextDocumentClientCapabilities.CodeAction(
        codeActionLiteralSupport: TextDocumentClientCapabilities.CodeAction
          .CodeActionLiteralSupport(
            codeActionKind: TextDocumentClientCapabilities.CodeAction.CodeActionLiteralSupport
              .CodeActionKind(valueSet: [])
          )
      )
    )
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

  private func inlayHints(_ req: InlayHintRequest) async throws -> [InlayHint] {
    if self.otherSettings.disableInlayHints { return [] }
    return collectInlayHints(self.findTree(req.textDocument.uri), req, self.mapper)
  }

  private func highlight(_ req: DocumentHighlightRequest) async throws -> [DocumentHighlight]? {
    return highlightTree(self.findTree(req.textDocument.uri), req, self.mapper)
  }

  // swiftlint:disable cyclomatic_complexity
  private func complete(_ req: CompletionRequest) async throws -> CompletionList {
    let begin = clock()
    var arr: [CompletionItem] = []
    let fp = req.textDocument.uri.fileURL!.path
    while self.parseTask != nil {

    }
    if let t = self.tree, let mt = t.findSubdirTree(file: fp), mt.ast != nil,
      let content = self.getContents(file: fp)
    {
      let pos = req.position
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
    var insertions: Set<String> = []
    var realRet: [CompletionItem] = []
    for completion in arr where !insertions.contains(completion.insertText!) {
      insertions.insert(completion.insertText!)
      realRet.append(completion)
    }
    Timing.INSTANCE.registerMeasurement(name: "complete", begin: begin, end: clock())
    return CompletionList(isIncomplete: false, items: realRet)
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

  private func documentSymbol(_ req: DocumentSymbolRequest) async throws -> DocumentSymbolResponse?
  { return collectDocumentSymbols(self.findTree(req.textDocument.uri), req, self.mapper) }

  private func formatting(_ req: DocumentFormattingRequest) async throws -> [TextEdit] {
    let begin = clock()
    do {
      Self.LOG.info("Formatting \(req.textDocument.uri.fileURL!.path)")
      if let contents = self.getContents(file: req.textDocument.uri.fileURL!.path) {
        if let formatted = try formatFile(
          content: contents,
          params: req.options,
          muonPath: self.otherSettings.muonPath
        ) {
          Self.LOG.info(
            "Finished formatting document (New: \(formatted.count); Old: \(contents.count))"
          )
          let newLines = formatted.split(whereSeparator: \.isNewline)
          let endOfLastLine = newLines.isEmpty ? 1024 : (newLines[newLines.count - 1].count)
          let range =
            Position(
              line: 0,
              utf16index: 0
            )..<Position(line: newLines.count + 2048, utf16index: endOfLastLine)
          let edit = TextEdit(range: range, newText: formatted)
          Timing.INSTANCE.registerMeasurement(name: "formatting", begin: begin, end: clock())
          if let sb = self.findSubprojectForUri(req.textDocument.uri),
            let csp = sb as? FolderSubproject
          {
            self.rebuildSubproject(csp)
          }
          return [edit]
        } else {
          Self.LOG.error("Unable to format file")
        }
      } else {
        Self.LOG.error("Unable to read file")
      }
    } catch {
      Self.LOG.error("Error formatting file \(error)")
      Timing.INSTANCE.registerMeasurement(name: "formatting", begin: begin, end: clock())
      throw ResponseError(code: .internalError, message: "Unable to format using muon: \(error)")
    }
    Timing.INSTANCE.registerMeasurement(name: "formatting", begin: begin, end: clock())
    throw ResponseError(
      code: .internalError,
      message: "Either failed to read the input file or to format using muon"
    )
  }

  private func getContents(file: String) -> String? {
    if let sf = self.memfiles[file] { return sf }
    Self.LOG.warning("Unable to find \(file) in memfiles")
    return try? String(contentsOfFile: file)
  }

  private func hover(_ req: HoverRequest) -> HoverResponse? {
    return collectHoverInformation(self.findTree(req.textDocument.uri), req, self.mapper, docs)
  }

  private func declaration(_ req: DeclarationRequest) async throws
    -> LocationsOrLocationLinksResponse?
  { return findDeclaration(self.findTree(req.textDocument.uri), req, self.mapper, Self.LOG) }

  private func definition(_ req: DefinitionRequest) async throws
    -> LocationsOrLocationLinksResponse?
  { return findDefinition(self.findTree(req.textDocument.uri), req, self.mapper, Self.LOG) }

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
        memfiles: self.memfiles
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
        memfiles: self.memfiles,
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
          memfiles: self.memfiles,
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

  private func openDocument(_ note: DidOpenTextDocumentNotification) async {
    if let sb = self.findSubprojectForUri(note.textDocument.uri) {
      if sb is FolderSubproject {
        let file = note.textDocument.uri.fileURL?.path
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
      let file = note.textDocument.uri.fileURL?.path
      self.openFiles.insert(file!)
      self.astCache.removeValue(forKey: file!)
    }
  }

  private func didSaveDocument(_ note: DidSaveTextDocumentNotification) async {
    if let sb = self.findSubprojectForUri(note.textDocument.uri) {
      if sb is FolderSubproject {
        let file = note.textDocument.uri.fileURL?.path
        Self.LOG.info("[Save] \(file!) in subproject \(sb.realpath)")
        self.memfiles.removeValue(forKey: file!)
        self.rebuildSubproject(sb)
      }
    } else {
      let file = note.textDocument.uri.fileURL?.path
      // Either the saves were changed or dropped, so use the contents
      // of the file
      Self.LOG.info("[Save] Dropping \(file!) from memcache")
      self.memfiles.removeValue(forKey: file!)
      self.rebuildTree()
    }
  }

  private func closeDocument(_ note: DidCloseTextDocumentNotification) async {
    if let sb = self.findSubprojectForUri(note.textDocument.uri) {
      if sb is FolderSubproject {
        let file = note.textDocument.uri.fileURL?.path
        Self.LOG.info("[Close] \(file!) in subproject \(sb.realpath)")
        Self.LOG.info("\(self.openSubprojectFiles.keys)")
        if var s = self.openSubprojectFiles[sb.realpath] {
          s.remove(file!)
          self.openSubprojectFiles[sb.realpath] = s
        }
        self.memfiles.removeValue(forKey: file!)
        self.rebuildSubproject(sb)
      }
    } else {
      let file = note.textDocument.uri.fileURL?.path
      // Either the saves were changed or dropped, so use the contents
      // of the file
      Self.LOG.info("[Close] Dropping \(file!) from memcache")
      self.openFiles.remove(file!)
      self.memfiles.removeValue(forKey: file!)
      self.rebuildTree()
    }
  }

  private func changeDocument(_ note: DidChangeTextDocumentNotification) async {
    if let sb = self.findSubprojectForUri(note.textDocument.uri) {
      if sb is FolderSubproject {
        let file = note.textDocument.uri.fileURL?.path
        Self.LOG.info("[Change] \(file!) in subproject \(sb.realpath)")
        self.memfiles[file!] = note.contentChanges[0].text
        self.rebuildSubproject(sb)
      }
    } else {
      let file = note.textDocument.uri.fileURL?.path
      Self.LOG.info("[Change] Adding \(file!) to memcache")
      self.memfiles[file!] = note.contentChanges[0].text
      self.rebuildTree()
    }
  }

  private func didCreateFiles(_ note: DidCreateFilesNotification) async { self.rebuildTree() }
  // swiftlint:disable cyclomatic_complexity
  private func parseOptions(settings: LSPAny) {
    // swiftlint:disable force_try
    let dict = try! settings.asDictionary()
    // swiftlint:enable force_try
    if let others = dict["others"] as? [String: Any] {
      var ignoreDiagnosticsFromSubprojects: [String]?
      var neverDownloadAutomatically = false
      var disableInlayHints = false
      var muonPath: String?
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
      if let disableInlay = others["disableInlayHints"] as? Bool {
        disableInlayHints = disableInlay
      }
      if let muon = others["muonPath"] as? String { muonPath = muon }
      self.otherSettings = OtherSettings(
        ignoreDiagnosticsFromSubprojects: ignoreDiagnosticsFromSubprojects,
        neverDownloadAutomatically: neverDownloadAutomatically,
        disableInlayHints: disableInlayHints,
        muonPath: muonPath
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
      await self.setSubprojects(nil)
      await self.setupSubprojects()
    }
    self.rebuildTree()
  }
  // swiftlint:enable cyclomatic_complexity

  private func didChangeConfiguration(_ note: DidChangeConfigurationNotification) async {
    let config = note.settings
    if case .unknown(let settings) = config { self.parseOptions(settings: settings) }
  }

  private func didDeleteFiles(_ note: DidDeleteFilesNotification) async {
    for f in note.files {
      let path = f.uri.fileURL!.path
      if self.memfiles[path] != nil { self.memfiles.removeValue(forKey: path) }
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
      foldingRangeProvider: .bool(true),
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
    do { _ = try await self.client.send(workDoneCreate) } catch let err { Self.LOG.error("\(err)") }
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
      self.subprojects = try SubprojectState(
        rootDir: self.path!,
        onProgress: onProgress,
        disableDownloads: self.otherSettings.neverDownloadAutomatically
      )
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
    if self.subprojects == nil {
      let endMessage = WorkDoneProgress(
        token: t,
        value: WorkDoneProgressKind.end(WorkDoneProgressEnd())
      )
      self.client.send(endMessage)
      return
    }
    for err in self.subprojects!.errors {
      Self.LOG.error("Got error during setting up subprojects: \(err)")
    }
    Self.LOG.info("Setup all directories for subprojects")
    if self.subprojects == nil {
      let endMessage = WorkDoneProgress(
        token: t,
        value: WorkDoneProgressKind.end(WorkDoneProgressEnd())
      )
      self.client.send(endMessage)
      return
    }
    let count = Double(self.subprojects!.subprojects.count)
    var n = 0
    if self.subprojects == nil {
      let endMessage = WorkDoneProgress(
        token: t,
        value: WorkDoneProgressKind.end(WorkDoneProgressEnd())
      )
      self.client.send(endMessage)
      return
    }
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
        memfiles: self.memfiles,
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
    if self.subprojects == nil {
      let endMessage = WorkDoneProgress(
        token: t,
        value: WorkDoneProgressKind.end(WorkDoneProgressEnd())
      )
      self.client.send(endMessage)
      return
    }
    self.mapper.subprojects = self.subprojects!
    Self.LOG.info("Setup all subprojects, rebuilding tree (If there were any found)")
    if self.subprojects == nil {
      let endMessage = WorkDoneProgress(
        token: t,
        value: WorkDoneProgressKind.end(WorkDoneProgressEnd())
      )
      self.client.send(endMessage)
      return
    }
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
      Task {
        await self.checkMtime()
        await self.scheduleNextMtimeCheck()
      }
    }
  }

  private func updateSubprojects() async {
    let t = ProgressToken.string(UUID().uuidString)
    self.token = t
    let workDoneCreate = CreateWorkDoneProgressRequest(token: t)
    do { _ = try await self.client.send(workDoneCreate) } catch let err { Self.LOG.error("\(err)") }
    let beginMessage = WorkDoneProgress(
      token: t,
      value: WorkDoneProgressKind.begin(
        WorkDoneProgressBegin(title: "Updating subprojects", percentage: 0)
      )
    )
    self.client.send(beginMessage)
    if self.subprojects == nil {
      let endMessage = WorkDoneProgress(
        token: t,
        value: WorkDoneProgressKind.end(WorkDoneProgressEnd())
      )
      self.client.send(endMessage)
      return
    }
    let count = Double(self.subprojects!.subprojects.count)
    var n = 0
    if self.subprojects == nil {
      let endMessage = WorkDoneProgress(
        token: t,
        value: WorkDoneProgressKind.end(WorkDoneProgressEnd())
      )
      self.client.send(endMessage)
      return
    }
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
          memfiles: self.memfiles,
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
    if self.subprojects == nil {
      let endMessage = WorkDoneProgress(
        token: t,
        value: WorkDoneProgressKind.end(WorkDoneProgressEnd())
      )
      self.client.send(endMessage)
      return
    }
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
  // swiftlint:enable cyclomatic_complexity

  private func initialize(_ req: InitializeRequest) async throws -> InitializeResult {
    let p = req
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
    Self.LOG.info(
      "Swift-MesonLSP is licensed under the terms of the GNU General Public License v3.0"
    )
    Self.LOG.info(
      "Need help? - Open a discussion here: https://github.com/JCWasmx86/Swift-MesonLSP/discussions or join https://matrix.to/#/#mesonlsp:matrix.org"
    )
    return InitializeResult(capabilities: self.capabilities(supportsRenaming))
  }

  private func workspaceSymbols(_ req: WorkspaceSymbolsRequest) -> [WorkspaceSymbolItem]? {
    return []
  }

  private func clientInitialized(_: InitializedNotification) async {
    // Nothing to do.
  }

  private nonisolated func cancelRequest(_ notification: CancelRequestNotification) {
    // No cancellation for anything supported (yet?)
  }

  private func shutdown(_ request: ShutdownRequest) async throws -> VoidResponse {
    self.prepareForExit()
    return VoidResponse()
  }

  private func exit(_ notification: ExitNotification) async {
    self.prepareForExit()
    self.onExit()
  }

  public nonisolated func handle(_ params: some NotificationType, from clientID: ObjectIdentifier) {
    if let params = params as? CancelRequestNotification {
      // Request cancellation needs to be able to overtake any other message we
      // are currently handling. Ordering is not important here. We thus don't
      // need to execute it on `messageHandlingQueue`.
      self.cancelRequest(params)
    }

    messageHandlingQueue.async(metadata: TaskMetadata(params)) {
      let notificationID = await self.getNextNotificationIDForLogging()

      await withLoggingScope("notification-\(notificationID)") {
        await self.handleImpl(params, from: clientID)
      }
    }
  }

  private func getNextNotificationIDForLogging() -> Int {
    notificationIDForLogging += 1
    return notificationIDForLogging
  }

  private func handleImpl(_ notification: some NotificationType, from clientID: ObjectIdentifier)
    async
  {
    Self.LOG.debug(
      """
      Received notification
      \(notification.forLogging)
      """
    )

    switch notification {
    case let notification as InitializedNotification: await self.clientInitialized(notification)
    case let notification as ExitNotification: await self.exit(notification)
    case let notification as DidOpenTextDocumentNotification: await self.openDocument(notification)
    case let notification as DidCloseTextDocumentNotification:
      await self.closeDocument(notification)
    case let notification as DidChangeTextDocumentNotification:
      await self.changeDocument(notification)
    case let notification as DidSaveTextDocumentNotification:
      await self.didSaveDocument(notification)
    // IMPORTANT: When adding a new entry to this switch, also add it to the `TaskMetadata` initializer.
    default: break
    }
  }

  private func handleRequest<R: RequestType>(
    _ request: Request<R>,
    handler: (R) async throws -> R.Response
  ) async {
    do { request.reply(try await handler(request.params)) } catch {
      request.reply(.failure(ResponseError.unknown("\(error)")))
    }
  }

  public nonisolated func handle<R: RequestType>(
    _ params: R,
    id: RequestID,
    from clientID: ObjectIdentifier,
    reply: @escaping (LSPResult<R.Response>) -> Void
  ) {
    self.messageHandlingQueue.async(metadata: TaskMetadata(params)) {
      await withLoggingScope("request-\(id)") {
        await self.handleImpl(params, id: id, from: clientID, reply: reply)
      }
    }
  }

  // swiftlint:disable cyclomatic_complexity
  private func handleImpl<R: RequestType>(
    _ params: R,
    id: RequestID,
    from clientID: ObjectIdentifier,
    reply: @escaping (LSPResult<R.Response>) -> Void
  ) async {
    let startDate = Date()

    let request = Request(params, id: id, clientID: clientID) { result in
      reply(result)
      let endDate = Date()
      Task {
        switch result {
        case .success(let response):
          Self.LOG.debug(
            """
            Succeeded (took \(endDate.timeIntervalSince(startDate) * 1000)ms)
            \(response)
            """
          )
        case .failure(let error):
          Self.LOG.debug(
            """
            Failed (took \(endDate.timeIntervalSince(startDate) * 1000)ms)
            \(R.method)
            \(error.forLogging)
            """
          )
        }
      }
    }

    logger.debug("Received request: \(request.forLogging)")

    switch request {
    case let request as Request<InitializeRequest>:
      await self.handleRequest(request, handler: self.initialize)
    case let request as Request<ShutdownRequest>:
      await self.handleRequest(request, handler: self.shutdown)
    case let request as Request<CompletionRequest>:
      await self.handleRequest(request, handler: self.complete)
    case let request as Request<HoverRequest>:
      await self.handleRequest(request, handler: self.hover)
    case let request as Request<DeclarationRequest>:
      await self.handleRequest(request, handler: self.declaration)
    case let request as Request<DefinitionRequest>:
      await self.handleRequest(request, handler: self.definition)
    case let request as Request<DocumentHighlightRequest>:
      await self.handleRequest(request, handler: self.highlight)
    case let request as Request<FoldingRangeRequest>:
      await self.handleRequest(request, handler: self.foldingRanges)
    case let request as Request<DocumentSymbolRequest>:
      await self.handleRequest(request, handler: self.documentSymbol)
    case let request as Request<DocumentSemanticTokensRequest>:
      await self.handleRequest(request, handler: self.semanticTokenFull)
    case let request as Request<CodeActionRequest>:
      await self.handleRequest(request, handler: self.codeActions)
    case let request as Request<InlayHintRequest>:
      await self.handleRequest(request, handler: self.inlayHints)
    case let request as Request<RenameRequest>:
      await self.handleRequest(request, handler: self.rename)
    case let request as Request<WorkspaceSymbolsRequest>:
      await self.handleRequest(request, handler: self.workspaceSymbols)
    case let request as Request<DocumentFormattingRequest>:
      await self.handleRequest(request, handler: self.formatting)
    // IMPORTANT: When adding a new entry to this switch, also add it to the `TaskMetadata` initializer.
    default: reply(.failure(ResponseError.methodNotFound(R.method)))
    }
  }  // swiftlint:enable cyclomatic_complexity
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
  public let disableInlayHints: Bool
  public let muonPath: String?

  public init(
    ignoreDiagnosticsFromSubprojects: [String]?,
    neverDownloadAutomatically: Bool,
    disableInlayHints: Bool,
    muonPath: String?
  ) {
    self.ignoreDiagnosticsFromSubprojects = ignoreDiagnosticsFromSubprojects
    self.neverDownloadAutomatically = neverDownloadAutomatically
    self.disableInlayHints = disableInlayHints
    self.muonPath = muonPath
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
private enum TaskMetadata: DependencyTracker {
  case globalConfigurationChange
  case documentUpdate(DocumentURI)
  case documentRequest(DocumentURI)
  case freestanding

  /// Whether this request needs to finish before `other` can start executing.
  func isDependency(of other: Self) -> Bool {
    switch (self, other) {
    case (.globalConfigurationChange, _): return true
    case (_, .globalConfigurationChange): return true
    case (.documentUpdate(let selfUri), .documentUpdate(let otherUri)): return selfUri == otherUri
    case (.documentUpdate(let selfUri), .documentRequest(let otherUri)): return selfUri == otherUri
    case (.documentRequest(let selfUri), .documentUpdate(let otherUri)): return selfUri == otherUri
    case (.documentRequest, .documentRequest): return false
    case (.freestanding, _): return false
    case (_, .freestanding): return false
    }
  }

  // swiftlint:disable cyclomatic_complexity
  init(_ notification: any NotificationType) {
    switch notification {
    case is InitializedNotification: self = .globalConfigurationChange
    case is CancelRequestNotification: self = .freestanding
    case is ExitNotification: self = .globalConfigurationChange
    case let notification as DidOpenTextDocumentNotification:
      self = .documentUpdate(notification.textDocument.uri)
    case let notification as DidCloseTextDocumentNotification:
      self = .documentUpdate(notification.textDocument.uri)
    case let notification as DidChangeTextDocumentNotification:
      self = .documentUpdate(notification.textDocument.uri)
    case is DidChangeWorkspaceFoldersNotification: self = .globalConfigurationChange
    case is DidChangeWatchedFilesNotification: self = .freestanding
    case let notification as WillSaveTextDocumentNotification:
      self = .documentUpdate(notification.textDocument.uri)
    case let notification as DidSaveTextDocumentNotification:
      self = .documentUpdate(notification.textDocument.uri)
    default:
      logger.error(
        """
        Unknown notification \(type(of: notification)). Treating as a freestanding notification. \
        This might lead to out-of-order request handling
        """
      )
      self = .freestanding
    }
  }
  // swiftlint:enable cyclomatic_complexity

  init(_ request: any RequestType) {
    switch request {
    case is InitializeRequest: self = .globalConfigurationChange
    case is ShutdownRequest: self = .globalConfigurationChange
    case is WorkspaceSymbolsRequest: self = .freestanding
    case is RenameRequest: self = .freestanding
    case is DocumentFormattingRequest: self = .freestanding
    case let request as any TextDocumentRequest: self = .documentRequest(request.textDocument.uri)
    default:
      logger.error(
        """
        Unknown request \(type(of: request)). Treating as a freestanding notification. \
        This might lead to out-of-order request handling
        """
      )
      self = .freestanding
    }
  }
}
