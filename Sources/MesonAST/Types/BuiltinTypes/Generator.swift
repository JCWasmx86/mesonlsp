public struct Generator: AbstractObject {
  public let name: String = "generator"
  public var methods: [Method] = []
  public let parent: AbstractObject? = nil

  public init() {
    self.methods = [
      Method(
        name: "process",
        parent: self,
        returnTypes: [GeneratedList()],
        args: [
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: false,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "extra_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "preserve_path_from", opt: true, types: [Str()]),
        ]
      )
    ]
  }
}
