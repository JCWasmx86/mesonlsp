public struct ListType: Type {
  public let name: String = "list"
  public var methods: [Method] = []
  public var types: [Type]

  public init(types: [Type]) {
    self.types = types
    self.methods = [
      Method(
        name: "contains", parent: self, returnTypes: [BoolType()],
        args: [PositionalArgument(name: "item", types: [`Any`()])]),
      Method(
        name: "get", parent: self, returnTypes: [`Any`()],
        args: [
          PositionalArgument(name: "index", types: [`IntType`()]),
          PositionalArgument(name: "fallback", opt: true, types: [`Any`()]),
        ]), Method(name: "length", parent: self, returnTypes: [`IntType`()]),
    ]
  }

  public func toString() -> String {
    return "list(" + self.types.map { $0.toString() }.joined(separator: "|") + ")"
  }
}
