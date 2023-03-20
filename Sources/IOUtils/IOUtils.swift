import Foundation

class Constants {
	static let CURR_URL: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
}
public func readFile(_ path: String) throws -> String {
  let fileURL = URL(fileURLWithPath: path)
  let data = try Data(contentsOf: fileURL)
  return String(data: data, encoding: .utf8)!
}

public func makeAbsolute(_ path: String) -> String {
	if path.first == "/" {
		return path
	}
  return makeAbsolute_(path).path
}

func makeAbsolute_(_ path: String) -> URL {
	return URL(
    fileURLWithPath: path,
    relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
  )
}

public func getParent(_ path: String) -> String {
	return normalizePath_(path + "/..")
}

public func fileExists(_ path: String) -> Bool {
  return FileManager.default.fileExists(atPath: path)
}

public func normalizePath_(_ path: String) -> String {
	return URL(
    fileURLWithPath: path,
    relativeTo: Constants.CURR_URL
  ).standardizedFileURL.path
}

public func normalizePath(_ path: String) -> String {
  return URL(
    fileURLWithPath: path,
    relativeTo: Constants.CURR_URL
  ).standardizedFileURL.path
}
