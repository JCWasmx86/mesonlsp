import ArgumentParser
import ConsoleKit
import Dispatch
import Foundation
import LanguageServer
import LanguageServerProtocol
import LanguageServerProtocolJSONRPC
import Logging
import LSPLogging
import MesonAnalyze
import MesonAST
import SwiftTreeSitter
import TestingFramework
import TreeSitterMeson

@main public struct MesonLSP: ParsableCommand {
  static let NUM_PARSES = 100
  public init() {

  }
  @ArgumentParser.Option var path: String = "./meson.build"
  @ArgumentParser.Argument var paths: [String] = []
  @ArgumentParser.Flag var lsp: Bool = false
  @ArgumentParser.Flag var stdio: Bool = false
  @ArgumentParser.Flag var test: Bool = false
  @ArgumentParser.Flag var benchmark: Bool = false
  @ArgumentParser.Flag var interpret: Bool = false
  @ArgumentParser.Flag var keepCache: Bool = false

  func parseNTimes() {
    let console = Terminal()
    LoggingSystem.bootstrap({ label in var logger = ConsoleLogger(label: label, console: console)
      logger.logLevel = .debug
      return logger
    })
    let ns = TypeNamespace()
    var cache: [String: MesonAST.Node] = [:]
    var t = MesonTree(file: self.path, ns: ns, dontCache: [], cache: &cache)
    t.analyzeTypes(ns: ns, dontCache: [], cache: &cache)
    for _ in 0..<MesonLSP.NUM_PARSES {
      if !self.keepCache { cache.removeAll() }
      t = MesonTree(file: self.path, ns: ns, dontCache: [], cache: &cache)
      t.analyzeTypes(ns: ns, dontCache: [], cache: &cache)
    }
  }

  func parseEachProject() {
    let console = Terminal()
    LoggingSystem.bootstrap({ label in var logger = ConsoleLogger(label: label, console: console)
      logger.logLevel = self.test ? .trace : .debug
      return logger
    })
    let logger = Logger(label: "Swift-MesonLSP::MesonLSP")
    let ns = TypeNamespace()
    if self.test {
      logger.info("Testing \(paths.count) projects")
    } else {
      logger.info("Parsing \(paths.count) projects")
    }
    if self.test {
      var fail = false
      var cache: [String: MesonAST.Node] = [:]
      for p in self.paths {
        let t = MesonTree(file: p, ns: ns, dontCache: [], cache: &cache)
        if !self.keepCache { cache.removeAll() }
        t.analyzeTypes(ns: ns, dontCache: [], cache: &cache)
        var s: Set<MesonTree> = [t]
        var files: [String] = []
        while !s.isEmpty {
          let mt = s.removeFirst()
          files.append(mt.file)
          mt.subfiles.forEach({ s.insert($0) })
        }
        var checks: [String: [AssertionCheck]] = [:]
        files.forEach({ checks[$0] = parseAssertions(name: $0) })
        let tr = TestRunner(tree: t, assertions: checks)
        if !fail { fail = tr.failures != 0 || tr.notRun != 0 }
      }
      if fail {
        logger.critical("Some testcases failed")
        _Exit(1)
      }
    } else {
      parseAndPrintDiagnostics(ns: ns)
    }
  }

  func parseAndPrintDiagnostics(ns: TypeNamespace) {
    for p in self.paths {
      var cache: [String: MesonAST.Node] = [:]
      let t = MesonTree(file: p, ns: ns, dontCache: [], cache: &cache)
      t.analyzeTypes(ns: ns, dontCache: [], cache: &cache)
      if let mt = t.metadata {
        for kv in mt.diagnostics {
          for diag in kv.value {
            let sev = diag.severity == .error ? "🔴" : "⚠️"
            print("\(kv.key):\(diag.startLine + 1):\(diag.startColumn): \(sev) \(diag.message)")
          }
        }
      }
    }
  }

  func doBenchmark() {
    for path in paths {
      let ns = TypeNamespace()
      var cache: [String: MesonAST.Node] = [:]
      var t = MesonTree(file: path, ns: ns, dontCache: [], cache: &cache)
      t.analyzeTypes(ns: ns, dontCache: [], cache: &cache)
      for _ in 0..<MesonLSP.NUM_PARSES * 10 {
        if !self.keepCache { cache.removeAll() }
        t = MesonTree(file: path, ns: ns, dontCache: [], cache: &cache)
        t.analyzeTypes(ns: ns, dontCache: [], cache: &cache)
      }
    }
  }

  public mutating func run() {
    // LSP-Logging
    Logger.shared.currentLevel = self.stdio ? .error : .info
    if !lsp && paths.isEmpty && !self.benchmark && !self.interpret {
      self.parseNTimes()
      return
    } else if !lsp && !paths.isEmpty && !self.benchmark && !self.interpret {
      self.parseEachProject()
      return
    } else if self.benchmark && !self.interpret {
      self.doBenchmark()
      return
    }
    let console = Terminal()
    LoggingSystem.bootstrap({ label in var logger = ConsoleLogger(label: label, console: console)
      logger.logLevel = .info
      return logger
    })
    let realStdout = dup(STDOUT_FILENO)
    if realStdout == -1 { fatalError("failed to dup stdout: \(strerror(errno)!)") }
    close(STDOUT_FILENO)
    if dup2(STDERR_FILENO, STDOUT_FILENO) == -1 {
      fatalError("failed to redirect stdout -> stderr: \(strerror(errno)!)")
    }
    let realStdoutHandle = FileHandle(fileDescriptor: realStdout, closeOnDealloc: false)

    let clientConnection = JSONRPCConnection(
      protocol: MessageRegistry(
        requests: builtinRequests,
        notifications: builtinNotifications + [DidSaveTextDocumentNotification.self]
      ),
      inFD: FileHandle(fileDescriptor: STDIN_FILENO, closeOnDealloc: false),
      outFD: realStdoutHandle,
      syncRequests: false
    )
    let server = MesonServer(
      client: clientConnection,
      onExit: {
        clientConnection.close()
        return
      }
    )
    clientConnection.start(
      receiveHandler: server,
      closeHandler: {
        server.prepareForExit()
        withExtendedLifetime(realStdoutHandle) {}
        _Exit(0)
      }
    )
    dispatchMain()
  }
}
