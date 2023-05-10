import Foundation
import LanguageServerProtocol
import MesonAST

internal struct Shared {
  internal static func isSortableFunction(_ f: Function) -> Int? {
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

  internal static func nodeToRange(_ node: Node) -> Range<Position> {
    let location = node.location
    return Position(
      line: Int(location.startLine),
      utf16index: Int(location.startColumn)
    )..<Position(line: Int(location.endLine), utf16index: Int(location.endColumn))
  }
}
