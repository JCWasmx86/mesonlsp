import Foundation
import IOUtils

open class MesonSourceFile {
  public let file: String
  public var _contents: String
  public var _cached: Bool

  public init(file: String) {
    self.file = file
    self._contents = ""
    self._cached = false
  }

  open func contents() throws -> String {
    if self._cached { return self._contents }
    self._cached = true
    #if os(Windows)
      self._contents = try Path(self.file).read().replacingOccurrences(of: "\r\n", with: "\n")
    #else
      self._contents = try Path(self.file).read()
    #endif
    return self._contents
  }
}
