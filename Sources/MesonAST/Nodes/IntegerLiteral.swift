import SwiftTreeSitter

public final class IntegerLiteral: Expression {
  public let file: MesonSourceFile
  public let value: String
  public var types: [Type] = []
  public let location: Location
  public weak var parent: Node?

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.location = Location(node: node)
    self.value = string_value(file: file, node: node)
  }
  fileprivate init(file: MesonSourceFile, location: Location, value: String) {
    self.file = file
    self.location = location
    self.value = value
  }
  public func clone() -> Node {
    let location = self.location.clone()
    return IntegerLiteral(file: file, location: location, value: self.value)
  }
  public func visit(visitor: CodeVisitor) { visitor.visitIntegerLiteral(node: self) }
  public func visitChildren(visitor: CodeVisitor) {}
  public func setParents() {

  }
  public var description: String { return "(IntegerLiteral \(value))" }

  public func parse() -> Int {
    let lower = self.value.lowercased()
    if lower.starts(with: "0x") {
      return Int(lower.replacingOccurrences(of: "0x", with: ""), radix: 16)!
    } else if lower.starts(with: "0b") {
      return Int(lower.replacingOccurrences(of: "0b", with: ""), radix: 2)!
    } else if lower.starts(with: "0o") {
      return Int(lower.replacingOccurrences(of: "0o", with: ""), radix: 8)!
    }
    return Int(lower)!
  }
}
