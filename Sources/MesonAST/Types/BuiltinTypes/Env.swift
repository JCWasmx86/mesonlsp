public struct Env: AbstractObject {
  public let name: String = "env"
  public var methods: [Method] = []
  public let parent: AbstractObject? = nil

  public init() {
    self.methods = [
      Method(
        name: "append",
        parent: self,
        args: [
          PositionalArgument(name: "variable", types: [Str()]),
          PositionalArgument(name: "value", varargs: true, opt: true, types: [Str()]),
          Kwarg(name: "separator", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "prepend",
        parent: self,
        args: [
          PositionalArgument(name: "variable", types: [Str()]),
          PositionalArgument(name: "value", varargs: true, opt: true, types: [Str()]),
          Kwarg(name: "separator", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "set",
        parent: self,
        args: [
          PositionalArgument(name: "variable", types: [Str()]),
          PositionalArgument(name: "value", varargs: true, opt: true, types: [Str()]),
          Kwarg(name: "separator", opt: true, types: [Str()]),
        ]
      ),
    ]
  }
}
