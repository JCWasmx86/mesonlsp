import MesonAST

public class MemoryFile: MesonSourceFile {
  public init(file: String, contents: String) {
    super.init(file: file)
    self._contents = contents
    self._cached = true

  }

  open override func contents() throws -> String { return self._contents }
}
