import ArgumentParser
import Dispatch
import Foundation
import LanguageServer
import LanguageServerProtocol
import LanguageServerProtocolJSONRPC
import MesonAST
import MesonAnalyze
import SwiftTreeSitter
import TreeSitterMeson

@main public struct MesonLSP: ParsableCommand {
  public init() {

  }
  @Option var path: String = "./meson.build"
  @Flag var lsp: Bool = false

  public mutating func run() throws {
    if !lsp {
      let ns = TypeNamespace()
      var t = try MesonTree(file: self.path, ns: ns)
      t.analyzeTypes()
      for _ in 0..<100 {
        t = try MesonTree(file: self.path, ns: ns)
        t.analyzeTypes()
      }
      return
    }
    let realStdout = dup(STDOUT_FILENO)
    if realStdout == -1 { fatalError("failed to dup stdout: \(strerror(errno)!)") }
    if dup2(STDERR_FILENO, STDOUT_FILENO) == -1 {
      fatalError("failed to redirect stdout -> stderr: \(strerror(errno)!)")
    }
    let realStdoutHandle = FileHandle(fileDescriptor: realStdout, closeOnDealloc: false)

    let clientConnection = JSONRPCConnection(
      protocol: MessageRegistry.lspProtocol, inFD: FileHandle.standardInput,
      outFD: realStdoutHandle, syncRequests: false)
    let server = MesonServer(
      client: clientConnection,
      onExit: {
        clientConnection.close()
        return
      })
    clientConnection.start(
      receiveHandler: server,
      closeHandler: {
        server.prepareForExit()
        withExtendedLifetime(realStdoutHandle) {}
        _Exit(0)
      })
    dispatchMain()
  }
}
