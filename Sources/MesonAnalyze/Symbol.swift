import MesonAST

public class Symbol {
  public let name: String
  public let kind: UInt32
  public let startLine: UInt32
  public let startColumn: UInt32
  public let endLine: UInt32
  public let endColumn: UInt32
  // swiftlint:disable no_magic_numbers
  static let STRING_KIND = UInt32(15)
  static let INT_KIND = UInt32(16)
  static let BOOL_KIND = UInt32(17)
  static let LIST_KIND = UInt32(18)
  static let OBJECT_KIND = UInt32(19)
  static let VARIABLE_KIND = UInt32(13)
  // swiftlint:enable no_magic_numbers

  public init(id: IdExpression) {
    self.name = id.id
    self.startLine = id.location.startLine
    self.startColumn = id.location.startColumn
    self.endLine = id.location.endLine
    self.endColumn = id.location.endColumn
    self.kind = Self.newKind(id: id)
  }

  private static func newKind(id: IdExpression) -> UInt32 {
    if id.types.count == 1 {
      let t = id.types[0]
      if t.name == "str" { return Self.STRING_KIND }
      if t.name == "int" { return Self.INT_KIND }
      if t.name == "bool" { return Self.BOOL_KIND }
      if t.name == "list" { return Self.LIST_KIND }
      if t is AbstractObject { return Self.OBJECT_KIND }
    }
    return Self.VARIABLE_KIND
  }
}
