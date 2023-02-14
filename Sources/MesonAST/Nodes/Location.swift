import SwiftTreeSitter

public final class Location {
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

  init(_ sL: UInt32, _ eL: UInt32, _ sC: UInt32, _ eC: UInt32) {
    self.startLine = sL
    self.endLine = eL
    self.startColumn = sC
    self.endColumn = eC
  }

  public func clone() -> Location {
    return Location(self.startLine, self.endLine, self.startColumn, self.endColumn)
  }

  public func format() -> String {
    return "[\(startLine):\(startColumn)] -> [\(endLine):\(endColumn)]"
  }
}
