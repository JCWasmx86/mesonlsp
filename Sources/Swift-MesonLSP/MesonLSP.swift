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
import TreeSitterMeson

@main public struct MesonLSP: ParsableCommand {
  static let NUM_PARSES = 100
  public init() {

  }
  @ArgumentParser.Option var path: String = "./meson.build"
  @ArgumentParser.Argument var paths: [String] = []
  @ArgumentParser.Flag var lsp: Bool = false

  func parseNTimes() throws {
    let console = Terminal()
    LoggingSystem.bootstrap({ label in var cl = ConsoleLogger(label: label, console: console)
      cl.logLevel = .trace
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
    let logger = Logger(label: "Swift-MesonLSP::MesonLSP")
    LoggingSystem.bootstrap({ label in var cl = ConsoleLogger(label: label, console: console)
      cl.logLevel = .trace
      return cl
    })
    let ns = TypeNamespace()
    logger.info("Parsing \(paths.count) projects")
    for p in self.paths {
      let t = try MesonTree(file: p, ns: ns)
      t.analyzeTypes()
    }
  }

  public mutating func run() throws {
    // LSP-Logging
    Logger.shared.currentLevel = .info
    let console = Terminal()
    let logger = Logger(label: "Swift-MesonLSP::MesonLSP")
    if !lsp && paths.isEmpty {
      try self.parseNTimes()
      return
    } else if !lsp && !paths.isEmpty {
      try self.parseEachProject()
      return
    }
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
