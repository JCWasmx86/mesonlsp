public class `IntType`: Type {
  public let name: String = "int"
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(name: "is_even", parent: self, returnTypes: [BoolType()]),
      Method(name: "is_odd", parent: self, returnTypes: [BoolType()]),
      Method(
        name: "to_string", parent: self,
        returnTypes: [
          // Str()
        ]),
    ]
  }
  public func toString() -> String { return "int" }
}
