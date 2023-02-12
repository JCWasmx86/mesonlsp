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
  @ArgumentParser.Flag var test: Bool = false

  func parseNTimes() throws {
    let console = Terminal()
    LoggingSystem.bootstrap({ label in var cl = ConsoleLogger(label: label, console: console)
      cl.logLevel = .debug
      return cl
    })
    let ns = TypeNamespace()
    var t = try MesonTree(file: self.path, ns: ns)
    t.analyzeTypes()
    for _ in 0..<MesonLSP.NUM_PARSES {
      t = try MesonTree(file: self.path, ns: ns)
      t.analyzeTypes()
    }
  }

  func parseEachProject() throws {
    let console = Terminal()
    LoggingSystem.bootstrap({ label in var cl = ConsoleLogger(label: label, console: console)
      cl.logLevel = self.test ? .trace : .debug
      return cl
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
      for p in self.paths {
        let t = try MesonTree(file: p, ns: ns)
        t.analyzeTypes()
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
      for p in self.paths {
        let t = try MesonTree(file: p, ns: ns)
        t.analyzeTypes()
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
  }

  public mutating func run() throws {
    // LSP-Logging
    Logger.shared.currentLevel = .info
    if !lsp && paths.isEmpty {
      try self.parseNTimes()
      return
    } else if !lsp && !paths.isEmpty {
      try self.parseEachProject()
      return
    }
    let console = Terminal()
    let logger = Logger(label: "Swift-MesonLSP::MesonLSP")
    LoggingSystem.bootstrap({ label in ConsoleLogger(label: label, console: console) })
    let realStdout = dup(STDOUT_FILENO)
    if realStdout == -1 { fatalError("failed to dup stdout: \(strerror(errno)!)") }
    logger.info("Duplicating STDOUT_FILENO")
    if dup2(STDERR_FILENO, STDOUT_FILENO) == -1 {
      fatalError("failed to redirect stdout -> stderr: \(strerror(errno)!)")
    }
    let realStdoutHandle = FileHandle(fileDescriptor: realStdout, closeOnDealloc: false)

    let clientConnection = JSONRPCConnection(
      protocol: MessageRegistry(
        requests: builtinRequests,
        notifications: builtinNotifications + [DidSaveTextDocumentNotification.self]
      ),
      inFD: FileHandle.standardInput,
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
