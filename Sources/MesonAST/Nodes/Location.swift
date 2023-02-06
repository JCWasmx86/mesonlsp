import SwiftTreeSitter

public class Location {
  static let TREE_SITTER_BYTES_PER_CHAR = UInt32(2)
  public let startLine: UInt32
  public let endLine: UInt32
  public let startColumn: UInt32
  public let endColumn: UInt32

  public init(node: SwiftTreeSitter.Node) {
    self.startLine = node.pointRange.lowerBound.row
    // TODO: Why / TREE_SITTER_BYTES_PER_CHAR?
    self.startColumn = node.pointRange.lowerBound.column / Location.TREE_SITTER_BYTES_PER_CHAR
    self.endLine = node.pointRange.upperBound.row
    self.endColumn = node.pointRange.upperBound.column / Location.TREE_SITTER_BYTES_PER_CHAR
  }

  public init() {
    self.startLine = 0
    self.endLine = 0
    self.startColumn = 0
    self.endColumn = 0
  }

  public func format() -> String {
    return "[\(startLine):\(startColumn)] -> [\(endLine):\(endColumn)]"
  }
}
