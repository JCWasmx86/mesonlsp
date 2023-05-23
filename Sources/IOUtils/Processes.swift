import Foundation
import Logging

public struct Processes {
  internal static let LOG: Logger = Logger(label: "IOUtils::Processes")
  public static var PROCESSES: [Process] = []

  public static let CLEANUP_HANDLER: () -> Void = {
    PROCESSES.forEach { $0.terminate() }
    #if !os(Windows)
      PROCESSES.forEach { kill($0.processIdentifier, SIGKILL) }
    #endif
  }

  #if !os(Windows)
    public static func executeCommand(_ commands: [String], _ cwd: String? = nil) throws -> Int32 {
      let task = Process()
      let joined = commands.map { "\'\($0)\'" }.joined(separator: " ")
      Self.LOG.info("Executing \"\(joined)\" at \(cwd ?? "???")")
      task.arguments = ["-c", "\(joined)"]
      task.executableURL = URL(fileURLWithPath: "/bin/sh")
      if let c = cwd { task.currentDirectoryURL = URL(fileURLWithPath: c) }
      Self.PROCESSES.append(task)
      try task.run()
      task.waitUntilExit()
      Self.PROCESSES.remove(at: Self.PROCESSES.firstIndex(of: task)!)
      return task.terminationStatus
    }
  #else
    private static func getAbsolutePath(forExecutable executableName: String) throws -> String {
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
          "Command execution failed with exit code \(task.terminationStatus) in IOUtils::Processes::getAbsolutePath"
        )
      }
      return output!
    }

    public static func executeCommand(_ commands: [String], _ cwd: String? = nil) throws -> Int32 {
      guard let command = commands.first else { fatalError("Internal error") }

      let task = Process()
      if cwd != nil { task.currentDirectoryPath = cwd! }
      let lines = try getAbsolutePath(forExecutable: command)
      task.launchPath =
        Array(lines.replacingOccurrences(of: "\r\n", with: "\n").split(separator: "\n"))[0]
        .description
      task.arguments = Array(commands.dropFirst())
      Self.PROCESSES.append(task)
      task.launch()
      task.waitUntilExit()
      Self.PROCESSES.remove(at: Self.PROCESSES.firstIndex(of: task)!)
      return task.terminationStatus
    }
  #endif

  public static func download(url: String, outputFile: String) throws {
    do {
      _ = try self.executeCommand(["wget", url, "-O", outputFile, "-q", "-o", "/dev/stderr"])
    } catch {
      do { _ = try self.executeCommand(["curl", url, "-o", outputFile, "-s", "-L"]) } catch {
        throw error
      }
    }
  }
}
