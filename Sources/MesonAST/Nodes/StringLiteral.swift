import Foundation
import SwiftTreeSitter

public final class StringLiteral: Expression {
  public let file: MesonSourceFile
  public let id: String
  public var types: [Type] = []
  public let location: Location
  public weak var parent: Node?
  private let cache: String
  public let isFormat: Bool

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.isFormat = node.child(at: 0)!.nodeType == "string_format"
    self.file = file
    self.location = Location(node: node)
    self.id = string_value(file: file, node: node)
    if self.id != "''" && !self.id.isEmpty && self.id.count - 1 >= 1 {
      self.cache = self.id[1..<self.id.count - 1]
    } else {
      self.cache = ""
    }
  }

  public init(_ contents: String) {
    self.file = MesonSourceFile(file: "/dev/null")
    self.id = "\"\(contents)\""
    self.location = Location(0, 0, 1, 1)
    self.cache = contents
    self.isFormat = false
  }

  fileprivate init(
    file: MesonSourceFile,
    location: Location,
    id: String,
    cache: String,
    isFormat: Bool
  ) {
    self.file = file
    self.location = location
    self.id = id
    self.cache = cache
    self.isFormat = isFormat
  }
  public func clone() -> Node {
    let location = self.location.clone()
    return Self(
      file: file,
      location: location,
      id: self.id,
      cache: self.cache,
      isFormat: self.isFormat
    )
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
