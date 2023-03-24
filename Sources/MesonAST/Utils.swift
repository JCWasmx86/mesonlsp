import Foundation
import SwiftTreeSitter

// There seem to be some name collisions
public typealias MesonVoid = ()

extension SwiftTreeSitter.Node {
  public func enumerateNamedChildren(block: (SwiftTreeSitter.Node) -> MesonVoid) {
    for i in 0..<namedChildCount {
      let n = namedChild(at: i)!
      block(n)
    }
  }
}

internal func string_value(file: MesonSourceFile, node: SwiftTreeSitter.Node) -> String {
  if let text = try? file.contents() {
    if let r2 = Range(node.range, in: text) {
      return text[r2].trimmingCharacters(in: .whitespacesAndNewlines)
    } else {
      print("Unable to find range \(node.range.description) for text\n\(text)")
    }
  }
  return ""
}
