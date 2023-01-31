import ArgumentParser
import ConsoleKit
import Dispatch
import Foundation
import LSPLogging
import LanguageServer
import LanguageServerProtocol
import LanguageServerProtocolJSONRPC
import Logging
import MesonAST
import MesonAnalyze
import SwiftTreeSitter
import TreeSitterMeson

@main public struct MesonLSP: ParsableCommand {
  public init() {

  }
  @ArgumentParser.Option var path: String = "./meson.build"
  @ArgumentParser.Argument var paths: [String] = []
  @ArgumentParser.Flag var lsp: Bool = false

  public mutating func run() throws {
    // LSP-Logging
    Logger.shared.currentLevel = .info
    let console = Terminal()
    LoggingSystem.bootstrap({ label in ConsoleLogger(label: label, console: console) })
    if !lsp && paths.isEmpty {
      let ns = TypeNamespace()
      var t = try MesonTree(file: self.path, ns: ns)
      t.analyzeTypes()
      for _ in 0..<100 {
        t = try MesonTree(file: self.path, ns: ns)
        t.analyzeTypes()
      }
      return
    } else if !lsp && !paths.isEmpty {
      let ns = TypeNamespace()
      print("Parsing", paths.count, "projects")
      for p in self.paths {
        let t = try MesonTree(file: p, ns: ns)
        t.analyzeTypes()
      }
      return
    }
    let logger = Logger(label: "Swift-MesonLSP::MesonLSP")
    let realStdout = dup(STDOUT_FILENO)
    if realStdout == -1 { fatalError("failed to dup stdout: \(strerror(errno)!)") }
    logger.info("Duplicating STDOUT_FILENO")
    if dup2(STDERR_FILENO, STDOUT_FILENO) == -1 {
      fatalError("failed to redirect stdout -> stderr: \(strerror(errno)!)")
    }
    let realStdoutHandle = FileHandle(fileDescriptor: realStdout, closeOnDealloc: false)

    let clientConnection = JSONRPCConnection(
      protocol: MessageRegistry.lspProtocol,
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
