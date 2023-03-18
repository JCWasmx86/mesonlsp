import Foundation
import PathKit

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
    self._contents = try Path(self.file).read()
    return self._contents
  }
}
