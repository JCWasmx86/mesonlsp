import MesonAST

public class Symbol {
  public let name: String
  public let kind: UInt32
  public let startLine: UInt32
  public let startColumn: UInt32
  public let endLine: UInt32
  public let endColumn: UInt32
  static let STRING_KIND = UInt32(15)
  static let INT_KIND = UInt32(16)
  static let BOOL_KIND = UInt32(17)
  static let LIST_KIND = UInt32(18)
  static let OBJECT_KIND = UInt32(19)
  static let VARIABLE_KIND = UInt32(13)

  public init(id: IdExpression) {
    self.name = id.id
    self.startLine = id.location.startLine
    self.startColumn = id.location.startColumn
    self.endLine = id.location.endLine
    self.endColumn = id.location.endColumn
    self.kind = Symbol.newKind(id: id)
  }

  private static func newKind(id: IdExpression) -> UInt32 {
    if id.types.count == 1 {
      let t = id.types[0]
      if t.name == "str" { return Symbol.STRING_KIND }
      if t.name == "int" { return Symbol.INT_KIND }
      if t.name == "bool" { return Symbol.BOOL_KIND }
      if t.name == "list" { return Symbol.LIST_KIND }
      if t is AbstractObject { return Symbol.OBJECT_KIND }
    }
    return Symbol.VARIABLE_KIND
  }
}
