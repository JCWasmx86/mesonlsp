public class `BoolType`: Type {
  public let name: String = "bool"
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "to_int", parent: self,
        returnTypes: [
          `IntType`()
        ]),
      Method(
        name: "to_string", parent: self,
        returnTypes: [
          Str()
        ]),
    ]
  }
}
