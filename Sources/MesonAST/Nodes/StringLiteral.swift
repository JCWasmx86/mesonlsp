import Foundation
import SwiftTreeSitter

public class StringLiteral: Expression {
  public let file: MesonSourceFile
  public let id: String
  public var types: [Type] = []
  public let location: Location
  public weak var parent: Node?
  private let cache: String

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.location = Location(node: node)
    self.id = string_value(file: file, node: node)
    if self.id != "''" && self.id != "" && 1 <= self.id.count - 1 {
      self.cache = self.id[1..<self.id.count - 1]
    } else {
      self.cache = ""
    }
  }
  public func visit(visitor: CodeVisitor) { visitor.visitStringLiteral(node: self) }
  public func visitChildren(visitor: CodeVisitor) {}

  public func contents() -> String { return self.cache }

  public func setParents() {

  }

  public var description: String { return "(StringLiteral \(id))" }
}
extension String {
  subscript(_ range: CountableRange<Int>) -> String {
    let start = index(startIndex, offsetBy: max(0, range.lowerBound))
    let end = index(
      start,
      offsetBy: min(self.count - range.lowerBound, range.upperBound - range.lowerBound)
    )
    return String(self[start..<end])
  }

  subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
    let start = index(startIndex, offsetBy: max(0, range.lowerBound))
    return String(self[start...])
  }
}
