import Foundation
import LanguageServerProtocol
import MesonAST

public struct Shared {
  public static func isSortableFunction(_ f: Function) -> Int? {
    let id = f.id()
    if id == "both_libraries" || id == "build_target" || id == "executable" || id == "jar"
      || id == "library" || id == "shared_library" || id == "shared_module"
      || id == "static_library"
    {
      return 1
    } else if id == "files" || id == "include_directories" || id == "install_data" {
      return 0
    }
    return nil
  }

  public static func stringValue(node: Node) -> String {
    do {
      let string = try node.file.contents()
      let lines = string.split(separator: "\n", omittingEmptySubsequences: false)
      if node.location.startLine == node.location.endLine {
        let line = lines[Int(node.location.startLine)]
        let sI = line.index(line.startIndex, offsetBy: Int(node.location.startColumn))
        let eI = line.index(line.startIndex, offsetBy: Int(node.location.endColumn - 1))
        return String(line[sI...eI])
      }
      let firstLine = String(lines[Int(node.location.startLine)])
      let sI = firstLine.index(firstLine.startIndex, offsetBy: Int(node.location.startColumn))
      let firstLine1 = String(firstLine[sI...])
      let lastLine = lines[Int(node.location.endLine)]
      let eI = lastLine.index(lastLine.startIndex, offsetBy: Int(node.location.endColumn - 1))
      let lastLine1 = String(lastLine[...eI])
      let sI1 = lines.index(lines.startIndex, offsetBy: Int(node.location.startLine + 1))
      let eI1 = lines.index(lines.startIndex, offsetBy: Int(node.location.endLine))
      let concatenated: String = Array(lines[sI1..<eI1].map { String($0) }).joined(separator: "\n")
      return String(firstLine1) + "\n" + concatenated + "\n" + String(lastLine1)
    } catch { return "Something went wrong" }
  }

  internal static func nodeToRange(_ node: Node) -> Range<Position> {
    let location = node.location
    return Position(
      line: Int(location.startLine),
      utf16index: Int(location.startColumn)
    )..<Position(line: Int(location.endLine), utf16index: Int(location.endColumn))
  }
}
