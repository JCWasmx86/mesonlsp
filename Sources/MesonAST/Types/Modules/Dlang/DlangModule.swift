public struct DlangModule: AbstractObject {
  public let name: String = "dlang_module"
  public let parent: AbstractObject? = Module()
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "generate_dub_file", parent: self, returnTypes: [],
        args: [
          PositionalArgument(name: "name", types: [Str()]),
          PositionalArgument(name: "source", types: [Str()]),
        ])
    ]
  }
}
