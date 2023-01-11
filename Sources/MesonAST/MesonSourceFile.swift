import Foundation

public class MesonSourceFile {
  public let file: String
  private var _contents: String
  private var cached: Bool
  public init(file: String) {
    self.file = file
    self._contents = ""
    self.cached = false

  }
  public func contents() throws -> String {
    if self.cached { return self._contents }
    self.cached = true
    self._contents = try NSString(
      contentsOfFile: self.file as String, encoding: String.Encoding.utf8.rawValue
    ).description
    return self._contents
  }
}
