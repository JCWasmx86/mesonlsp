public class ListType: Type {
  public let name: String = "list"
  public var methods: [Method] = []
  public var types: [Type]

  public init(types: [Type]) {
    self.types = types
    self.methods = [
      Method(
        name: "contains", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "get", parent: self,
        returnTypes: [
          `Any`()
        ]),
      Method(
        name: "length", parent: self,
        returnTypes: [
          `IntType`()
        ]),
    ]
  }
}
