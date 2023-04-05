import Foundation
import Wrap

public class WrapBasedSubproject: Subproject {
  private let wrap: Wrap

  public init(wrapName: String, wrap: Wrap, packagefiles: String, parent: Subproject?) throws {
    self.wrap = wrap
    try super.init(name: wrapName, parent: parent)
    try self.wrap.setupDirectory(path: self.getCacheDir(), packagefilesPath: packagefiles)
  }

  private func getCacheDir() -> String {
    let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
      ".cache",
      isDirectory: true
    ).appendingPathComponent("swift-mesonlsp", isDirectory: true).appendingPathComponent(
      "__wrap_setups__",
      isDirectory: true
    )
    do { try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true) } catch
    {}
    return url.appendingPathComponent("\(Date().timeIntervalSince1970)", isDirectory: true)
      .absoluteURL.path
  }
}
