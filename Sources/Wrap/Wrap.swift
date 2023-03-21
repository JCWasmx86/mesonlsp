import Foundation
import Logging

public class Wrap {
  private static let LOG: Logger = Logger(label: "Wrap::Wrap")
  public private(set) var directory: String?
  public private(set) var patchURL: String?
  public private(set) var patchFallbackURL: String?
  public private(set) var patchFilename: String?
  public private(set) var patchHash: String?
  public private(set) var patchDirectory: String?
  public private(set) var diffFiles: [String]?
  public private(set) var provides: Provides = Provides()
  public private(set) var wrapFile: String = ""

  internal init(
    directory: String?,
    patchURL: String?,
    patchFallbackURL: String?,
    patchFilename: String?,
    patchHash: String?,
    patchDirectory: String?,
    diffFiles: [String]?
  ) {
    self.directory = directory
    self.patchURL = patchURL
    self.patchFallbackURL = patchFallbackURL
    self.patchFilename = patchFilename
    self.patchHash = patchHash
    self.patchDirectory = patchDirectory
    self.diffFiles = diffFiles
  }

  internal func applyProvides(_ provides: Provides) { self.provides = provides }

  internal func setFile(_ file: String) { self.wrapFile = file }

  public func setupDirectory(path: String, packagefilesPath: String) throws {
    fatalError("Implement me")
  }

  internal func assertRequired(_ command: String) throws {
    let task = Process()
    Self.LOG.info("Checking if `\(command)` exists")
    task.arguments = ["-c", "which \(command)"]
    task.executableURL = URL(fileURLWithPath: "/bin/sh")
    try task.run()
    task.waitUntilExit()
    if task.terminationStatus != 0 {
      throw WrapError.commandNotFound("Required command `\(command)` not found")
    }
  }

  internal func executeCommand(_ commands: [String]) throws {
    let task = Process()
    let joined = commands.map { "\'\($0)\'" }.joined(separator: " ")
    Self.LOG.info("Executing \"\(joined)\"")
    task.arguments = ["-c", "\(joined)"]
    task.executableURL = URL(fileURLWithPath: "/bin/sh")
    try task.run()
    task.waitUntilExit()
    if task.terminationStatus != 0 {
      throw WrapError.genericError("Command failed with code \(task.terminationStatus): \(joined)")
    }
  }
}
