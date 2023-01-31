import MesonAST

public class Symbol {
  public let name: String
  public let kind: UInt32
  public let startLine: UInt32
  public let startColumn: UInt32
  public let endLine: UInt32
  public let endColumn: UInt32

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
      if t.name == "str" { return 15 }
      if t.name == "int" { return 16 }
      if t.name == "bool" { return 17 }
      if t.name == "list" { return 18 }
      if t is AbstractObject { return 19 }
    }
    return 13
  }
}
