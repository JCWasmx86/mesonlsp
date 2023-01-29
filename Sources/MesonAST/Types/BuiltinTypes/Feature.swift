public struct Feature: AbstractObject {
  public let name: String = "feature"
  public var methods: [Method] = []
  public let parent: AbstractObject? = nil

  public init() {
    self.methods = [
      Method(name: "allowed", parent: self, returnTypes: [BoolType()]),
      Method(name: "auto", parent: self, returnTypes: [BoolType()]),
      Method(
        name: "disable_auto_if",
        parent: self,
        returnTypes: [self],
        args: [PositionalArgument(name: "value", types: [BoolType()])]
      ), Method(name: "disabled", parent: self, returnTypes: [BoolType()]),
      Method(name: "enabled", parent: self, returnTypes: [BoolType()]),
      Method(
        name: "require",
        parent: self,
        returnTypes: [self],
        args: [
          PositionalArgument(name: "value", types: [BoolType()]),
          Kwarg(name: "error_message", opt: true, types: [Str()]),
        ]
      ),
    ]
  }
}
