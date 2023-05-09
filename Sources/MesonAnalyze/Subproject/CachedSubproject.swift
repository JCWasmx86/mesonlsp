import Foundation
import IOUtils
import MesonAST
import Wrap

public class CachedSubproject: Subproject {
  public let cachedPath: String

  public init(name: String, parent: Subproject?, path: String) throws {
    self.cachedPath = path
    try super.init(name: name, parent: parent)
  }

  public override func parse(
    _ ns: TypeNamespace,
    dontCache: Set<String>,
    cache: inout [String: MesonAST.Node],
    memfiles: [String: String]
  ) {
    if let children = try? Path(self.cachedPath).children(),
      let firstDirectory = children.first(where: { $0.isDirectory })
    {
      let t = MesonTree(
        file: self.cachedPath + Path.separator + (firstDirectory.lastComponent)
          + "\(Path.separator)meson.build",
        ns: ns,
        dontCache: dontCache,
        cache: &cache,
        memfiles: memfiles
      )
      t.analyzeTypes(ns: ns, dontCache: dontCache, cache: &cache, memfiles: memfiles)
      self.tree = t
    }
  }

  public override func update() throws {
    if let children = try? Path(self.cachedPath).children(),
      let firstDirectory = children.first(where: { $0.isDirectory })
    {
      let pullable =
        self.cachedPath + Path.separator + (firstDirectory.lastComponent)
        + "\(Path.separator).git_pullable"
      if !Path(pullable).exists { return }
      Self.LOG.info("Updating \(self)")
      try executeCommand(["git", "-C", Path(pullable).parent().description, "pull", "origin"])
      Self.LOG.info("Was successful updating \(self)")
    }
  }

  public override var description: String {
    return "CachedSubproject(\(name),\(realpath),\(cachedPath))"
  }
}
// This is copied from Wrap.swift. That's stupid. Move it to IOUtils'
#if !os(Windows)
  internal func executeCommand(_ commands: [String], _ cwd: String? = nil) throws {
    let task = Process()
    let joined = commands.map { "\'\($0)\'" }.joined(separator: " ")
    task.arguments = ["-c", "\(joined)"]
    task.executableURL = URL(fileURLWithPath: "/bin/sh")
    if let c = cwd { task.currentDirectoryURL = URL(fileURLWithPath: c) }
    Wrap.PROCESSES.append(task)
    try task.run()
    task.waitUntilExit()
    Wrap.PROCESSES.remove(at: Wrap.PROCESSES.firstIndex(of: task)!)
    if task.terminationStatus != 0 {
      throw WrapError.genericError("Command failed with code \(task.terminationStatus): \(joined)")
    }
  }
#else
  private func getAbsolutePath(forExecutable executableName: String) throws -> String {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "C:\\Windows\\System32\\where.exe")
    task.arguments = [executableName]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe

    try task.run()
    task.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)?.trimmingCharacters(
      in: .whitespacesAndNewlines
    )

    if task.terminationStatus != 0 {
      fatalError(
        "Command execution failed with exit code \(task.terminationStatus) during updating the cached subproject"
      )
    }
    return output!
  }

  internal func executeCommand(_ commands: [String], _ cwd: String? = nil) throws {
    guard let command = commands.first else { fatalError("Internal error") }

    let task = Process()
    if cwd != nil { task.currentDirectoryPath = cwd! }
    let lines = try getAbsolutePath(forExecutable: command)
    task.launchPath =
      Array(lines.replacingOccurrences(of: "\r\n", with: "\n").split(separator: "\n"))[0]
      .description
    task.arguments = Array(commands.dropFirst())
    Wrap.PROCESSES.append(task)
    task.launch()
    task.waitUntilExit()
    Wrap.PROCESSES.remove(at: Wrap.PROCESSES.firstIndex(of: task)!)

    if task.terminationStatus != 0 {
      throw WrapError.genericError(
        "Command execution failed with exit code \(task.terminationStatus)"
      )
    }
  }
#endif
