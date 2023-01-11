import SwiftTreeSitter

public class Location {
  public let startLine: UInt32
  public let endLine: UInt32
  public let startColumn: UInt32
  public let endColumn: UInt32

  public init(node: SwiftTreeSitter.Node) {
    self.startLine = node.pointRange.lowerBound.row
    self.startColumn = node.pointRange.lowerBound.column
    self.endLine = node.pointRange.upperBound.row
    self.endColumn = node.pointRange.upperBound.column
  }

  public init() {
    self.startLine = 0
    self.endLine = 0
    self.startColumn = 0
    self.endColumn = 0
  }
}
