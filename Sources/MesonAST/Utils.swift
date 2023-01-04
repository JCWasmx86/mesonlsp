import Foundation
import SwiftTreeSitter

extension SwiftTreeSitter.Node {
  public func enumerateNamedChildren(block: (SwiftTreeSitter.Node) -> Void) {
    for i in 0..<namedChildCount {
      let n = namedChild(at: i)!
      block(n)
    }
  }
}

func string_value(file: MesonSourceFile, node: SwiftTreeSitter.Node) -> String {
  if let text = try? file.contents() {
    return text.substring(
      with: node.range
    ).trimmingCharacters(in: .whitespacesAndNewlines)
  }
  return ""
}
