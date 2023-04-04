import Crypto
import Foundation
import IOUtils
import Logging

public class Wrap {
  internal static let LOG: Logger = Logger(label: "Wrap::Wrap")
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

  #if !os(Windows)
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

    internal func executeCommand(_ commands: [String], _ cwd: String? = nil) throws {
      let task = Process()
      let joined = commands.map { "\'\($0)\'" }.joined(separator: " ")
      Self.LOG.info("Executing \"\(joined)\" at \(cwd ?? "???")")
      task.arguments = ["-c", "\(joined)"]
      task.executableURL = URL(fileURLWithPath: "/bin/sh")
      if let c = cwd { task.currentDirectoryURL = URL(fileURLWithPath: c) }
      try task.run()
      task.waitUntilExit()
      if task.terminationStatus != 0 {
        throw WrapError.genericError(
          "Command failed with code \(task.terminationStatus): \(joined)"
        )
      }
    }
  #else
    func getAbsolutePath(forExecutable executableName: String) throws -> String {
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
          "Command execution failed with exit code \(task.terminationStatus) in Wrap::Wrap::getAbsolutePath"
        )
      }
      return output!
    }

    internal func assertRequired(_ command: String) throws {
      let task = Process()
      Self.LOG.info("Checking if `\(command)` exists")
      task.arguments = [command]
      task.executableURL = URL(fileURLWithPath: "C:\\Windows\\System32\\where.exe")
      try task.run()
      task.waitUntilExit()
      if task.terminationStatus != 0 {
        throw WrapError.commandNotFound("Required command `\(command)` not found")
      }
    }

    internal func executeCommand(_ commands: [String], _ cwd: String? = nil) throws {
      guard let command = commands.first else { fatalError("Internal error") }

      let task = Process()
      if cwd != nil { task.currentDirectoryPath = cwd! }
      let lines = try getAbsolutePath(forExecutable: command)
      task.launchPath = Array(lines.split(separator: "\r"))[0].description
      task.arguments = Array(commands.dropFirst())

      task.launch()
      task.waitUntilExit()

      if task.terminationStatus != 0 {
        throw WrapError.genericError(
          "Command execution failed with exit code \(task.terminationStatus)"
        )
      }
    }
  #endif

  internal func download(url: String, fallbackURL: String?, expectedHash: String) throws -> String {
    let tempPath = FileManager.default.temporaryDirectory.standardizedFileURL.path
    let outputFile = tempPath + Path.separator + UUID().uuidString
    Self.LOG.info("Attempting to download from \(url) to file \(outputFile)")
    do {
      try self.assertRequired("wget")
      try self.executeCommand(["wget", url, "-O", outputFile, "-q", "-o", "/dev/stderr"])
    } catch {
      do {
        try self.assertRequired("curl")
        try self.executeCommand(["curl", url, "-o", outputFile, "-s", "-L"])
      } catch {
        if let fb = fallbackURL {
          return try download(url: fb, fallbackURL: nil, expectedHash: expectedHash)
        }
        throw error
      }
    }
    let savedData = try Data(contentsOf: URL(fileURLWithPath: outputFile))
    let hashedBytes = Data(SHA256.hash(data: savedData)).hexStringEncoded()
    Self.LOG.info("Expected \(expectedHash), got \(hashedBytes)")
    if expectedHash != hashedBytes {
      if let fb = fallbackURL {
        return try download(url: fb, fallbackURL: nil, expectedHash: expectedHash)
      }
      throw WrapError.validationError("Expected \(expectedHash), got \(hashedBytes)")
    }
    return outputFile
  }

  internal func postSetup(path: String, packagesfilesPath: String) throws {
    try self.applyPatch(path: path, packagesfilesPath: packagesfilesPath)
    try self.applyDiffFiles(path: path, packagesfilesPath: packagesfilesPath)
  }

  private func applyPatch(path: String, packagesfilesPath: String) throws {
    if let patchDir = self.patchDirectory {
      let packagePath = Path(packagesfilesPath + Path.separator + patchDir)
      Self.LOG.info("Copying from \(packagePath) to \(path)")
      try mergeDirectories(
        from: URL(fileURLWithPath: packagePath.description),
        to: URL(fileURLWithPath: path)
      )
      return
    } else if self.patchFilename != nil, let url = self.patchURL, let hash = self.patchHash {
      // Download files, unpack in the parent directory of path
      let handleToPath = try self.download(
        url: url,
        fallbackURL: self.patchFallbackURL,
        expectedHash: hash
      )
      try extractArchive(type: .zip, file: handleToPath, outputDir: Path(path).parent().description)
    }
  }

  private func applyDiffFiles(path: String, packagesfilesPath: String) throws {
    if let diffs = diffFiles {
      for diff in diffs {
        Self.LOG.info("Applying diff \(diff)")
        let absoluteDiffPath = Path(packagesfilesPath + Path.separator + diff).absolute()
          .description
        do {
          try self.assertRequired("git")
          try self.executeCommand(
            ["git", "--work-tree", ".", "apply", "-p1", absoluteDiffPath],
            path
          )
        } catch {
          try self.assertRequired("patch")
          try self.executeCommand(["patch", "-f", "-p1", "-i", absoluteDiffPath], path)
        }
      }
    }
  }

  private func mergeDirectories(from sourceURL: URL, to destinationURL: URL) throws {
    let fileManager = FileManager.default
    let fileUrls = try fileManager.contentsOfDirectory(
      at: sourceURL,
      includingPropertiesForKeys: nil
    )

    for fileUrl in fileUrls {
      let destinationFileUrl = destinationURL.appendingPathComponent(fileUrl.lastPathComponent)
      if fileManager.fileExists(atPath: destinationFileUrl.path) {
        try fileManager.removeItem(at: destinationFileUrl)
      }
      if fileManager.fileExists(atPath: fileUrl.path) {
        if fileUrl.hasDirectoryPath {
          try fileManager.createDirectory(
            at: destinationFileUrl,
            withIntermediateDirectories: true,
            attributes: nil
          )
          try mergeDirectories(from: fileUrl, to: destinationFileUrl)
        } else {
          try fileManager.copyItem(at: fileUrl, to: destinationFileUrl)
        }
      }
    }
  }
}

extension Data {
  private static let hexAlphabet = Array("0123456789abcdef".unicodeScalars)

  public func hexStringEncoded() -> String {
    String(
      reduce(into: "".unicodeScalars) { result, value in
        result.append(Self.hexAlphabet[Int(value / 0x10)])
        result.append(Self.hexAlphabet[Int(value % 0x10)])
      }
    )
  }
}
