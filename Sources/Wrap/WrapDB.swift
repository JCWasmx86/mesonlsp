import Foundation
import IOUtils

public enum WrapDBError: Error {
  case badJSON
  case noSuchWrap
  case noVersion
}

public class WrapDB {
  public static let INSTANCE = WrapDB()
  internal var wraps: [String: WrapDBEntry] = [:]

  private init() {

  }

  public func initDB() async throws {
    // Download https://wrapdb.mesonbuild.com/v2/releases.json
    let tempPath = FileManager.default.temporaryDirectory.standardizedFileURL.path
    let outputFile = tempPath + Path.separator + UUID().uuidString
    try Processes.download(
      url: "https://wrapdb.mesonbuild.com/v2/releases.json",
      outputFile: outputFile
    )
    let json: String = try Path(outputFile).read()
    let jsonData = json.data(using: .utf8)!
    guard
      let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
        as? [String: Any]
    else { throw WrapDBError.badJSON }
    var wraps: [String: WrapDBEntry] = [:]
    for (dependencyName, dependencyData) in jsonObject {
      if let dependencyInfo = dependencyData as? [String: Any] {
        let dependencyNames = dependencyInfo["dependency_names"] as? [String]
        let versions = dependencyInfo["versions"] as? [String]
        wraps[dependencyName] = WrapDBEntry(dependencyName, dependencyNames, versions)
      }
    }
    self.wraps = wraps
  }

  public func containsWrap(_ name: String) -> Bool { return self.wraps[name] != nil }

  public func downloadWrapToString(_ name: String) throws -> String {
    guard let w = self.wraps[name] else { throw WrapDBError.noSuchWrap }
    guard let wrapversion = w.versions?.first else { throw WrapDBError.noVersion }
    // URL is https://wrapdb.mesonbuild.com/v2/{name}_{version}-{revision}/{name}.wrap
    // revision is the part after the - of the version
    let tempPath = FileManager.default.temporaryDirectory.standardizedFileURL.path
    let outputFile = tempPath + Path.separator + UUID().uuidString
    let url = "https://wrapdb.mesonbuild.com/v2/\(name)_\(wrapversion)/\(name).wrap"
    try Processes.download(url: url, outputFile: outputFile)
    return try Path(outputFile).read()
  }
}

internal class WrapDBEntry {
  internal let name: String
  internal let dependencyNames: [String]?
  internal let versions: [String]?

  internal init(_ name: String, _ deps: [String]?, _ versions: [String]?) {
    self.name = name
    self.dependencyNames = deps
    self.versions = versions
  }
}
