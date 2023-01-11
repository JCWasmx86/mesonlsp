import Foundation
import SwiftTreeSitter

public class StringLiteral: Expression {
  public let file: MesonSourceFile
  public let id: String
  public var types: [Type] = []

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.id = string_value(file: file, node: node)
  }
  public func visit(visitor: CodeVisitor) { visitor.visitStringLiteral(node: self) }
  public func visitChildren(visitor: CodeVisitor) {}

  public func contents() -> String { return self.id[1..<self.id.count - 1] }
}
extension String {
  subscript(_ range: CountableRange<Int>) -> String {
    let start = index(startIndex, offsetBy: max(0, range.lowerBound))
    let end = index(
      start, offsetBy: min(self.count - range.lowerBound, range.upperBound - range.lowerBound))
    return String(self[start..<end])
  }

  subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
    let start = index(startIndex, offsetBy: max(0, range.lowerBound))
    return String(self[start...])
  }
}
