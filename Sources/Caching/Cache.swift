import Crypto
import Foundation
import IOUtils
import Logging

public class Cache {
  private static let LOG = Logger(label: "Cache::Cache")
  public static let INSTANCE = Cache()
  private var cacheDir: Path

  private init() {
    let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
      ".cache",
      isDirectory: true
    ).appendingPathComponent("swift-mesonlsp", isDirectory: true).appendingPathComponent(
      "__cache__",
      isDirectory: true
    )
    do { try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true) } catch
    {}
    self.cacheDir = Path(url.absoluteURL.path)
  }

  public func cacheData(key: String, value: Path) {
    let filename = self.hash(key) + ".cached"
    do {
      try value.copy(self.cacheDir)
      Self.LOG.info("Stored data for key `\(key)` in \(filename)")
    } catch let error { Self.LOG.info("Caught error during copying file: \(error)") }
  }

  public func lookupData(key: String) -> String? {
    let filename = self.hash(key) + ".cached"
    let path = Path(cacheDir.description + Path.separator + filename)
    if path.exists {
      Self.LOG.info("Cache hit for key `\(key)`")
      return path.description
    }
    Self.LOG.info("Cache miss for key `\(key)`")
    return nil
  }

  private func hash(_ key: String) -> String {
    let data = key.data(using: .utf8)!
    return Data(SHA256.hash(data: data)).hexStringEncoded()
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
