public class Dict: Type {
  public let name: String = "dict"
  public var methods: [Method] = []
  public var types: [Type]

  public init(types: [Type]) {
    self.types = types
    self.methods = [
      Method(
        name: "get", parent: self,
        returnTypes: [
          `Any`()
        ],
        args: [
          PositionalArgument(
            name: "key",
            types: [
              Str()
            ]),
          PositionalArgument(
            name: "fallback", opt: true,
            types: [
              `Any`()
            ]),
        ]),
      Method(
        name: "has_key", parent: self,
        returnTypes: [
          `BoolType`()
        ],
        args: [
          PositionalArgument(
            name: "key",
            types: [
              Str()
            ])
        ]),
      Method(
        name: "keys", parent: self,
        returnTypes: [
          ListType(types: [Str()])
        ]),
    ]
  }
  public func toString() -> String {
    return "dict(" + self.types.map { $0.toString() }.joined(separator: "|") + ")"
  }
}
