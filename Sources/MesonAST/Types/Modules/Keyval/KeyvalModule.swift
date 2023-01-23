public struct KeyvalModule: AbstractObject {
  public let name: String = "keyval_module"
  public let parent: AbstractObject? = Module()
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "load", parent: self, returnTypes: [Dict(types: [Str()])],
        args: [PositionalArgument(name: "file", types: [File(), Str()])])
    ]
  }
}
