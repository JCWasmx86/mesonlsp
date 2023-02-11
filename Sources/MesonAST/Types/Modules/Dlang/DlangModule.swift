public struct DlangModule: AbstractObject {
  public let name: String = "dlang_module"
  public let parent: AbstractObject? = Module()
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "generate_dub_file",
        parent: self,
        returnTypes: [],
        args: [
          PositionalArgument(name: "name", types: [Str()]),
          PositionalArgument(name: "source", types: [Str()]),
          Kwarg(name: "authors", opt: true, types: [Str(), ListType(types: [Str()])]),
          Kwarg(name: "description", opt: true, types: [Str()]),
          // TODO: Derived just based on guessing
          Kwarg(name: "copyright", opt: true, types: [Str(), ListType(types: [Str()])]),
          Kwarg(name: "license", opt: true, types: [Str(), ListType(types: [Str()])]),
          Kwarg(name: "sourceFiles", opt: true, types: [Str(), ListType(types: [Str()])]),
          Kwarg(name: "targetType", opt: true, types: [Str()]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep(), Str()])]),
        ]
      )
    ]
  }
}
