public class Dict: Type {
  public let name: String = "dict"
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "get", parent: self,
        returnTypes: [
          `Any`()
        ]),
      Method(
        name: "has_key", parent: self,
        returnTypes: [
          `BoolType`()
        ]),
      Method(
        name: "keys", parent: self,
        returnTypes: [
          ListType(types: [Str()])
        ]),
    ]
  }
}
