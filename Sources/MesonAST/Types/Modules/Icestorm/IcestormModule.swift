public struct IcestormModule: AbstractObject {
  public let name: String = "icestorm_module"
  public let parent: AbstractObject? = Module()
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "project", parent: self, returnTypes: [ListType(types: [RunTgt(), CustomTgt()])],
        args: [
          PositionalArgument(name: "project_name", types: [Str()]),
          PositionalArgument(
            name: "files", types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]),
          Kwarg(
            name: "constraint_file",
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]),
        ])
    ]
  }
}
