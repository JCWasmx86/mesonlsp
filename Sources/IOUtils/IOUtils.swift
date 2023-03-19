import Foundation

public func readFile(_ path: String) throws -> String {
  let fileURL = URL(fileURLWithPath: path)
  let data = try Data(contentsOf: fileURL)
  return String(data: data, encoding: .utf8)!
}

public func makeAbsolute(_ path: String) -> String {
  return URL(
    fileURLWithPath: path,
    relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
  ).path
}

public func getParent(_ path: String) -> String {
  let url = URL(fileURLWithPath: path)
  return url.deletingLastPathComponent().path
}

public func fileExists(_ path: String) -> Bool {
  let fileManager = FileManager.default
  return fileManager.fileExists(atPath: path)
}

public func normalizePath(_ path: String) -> String {
  let url = URL(fileURLWithPath: path)
  let standardizedURL = url.standardizedFileURL
  return standardizedURL.path
}
