public struct RustModule: AbstractObject {
  public let name: String = "rust_module"
  public let parent: AbstractObject? = Module()
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "test",
        parent: self,
        returnTypes: [],
        args: [
          PositionalArgument(name: "name", types: [Str()]),
          PositionalArgument(name: "tgt", types: [BuildTgt()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str(), File(), Tgt()])]),
          Kwarg(name: "depends", opt: true, types: [ListType(types: [BuildTgt(), CustomTgt()])]),
          Kwarg(
            name: "env",
            opt: true,
            types: [Str(), ListType(types: [Str()]), Dict(types: [Str()])]
          ), Kwarg(name: "is_parallel", opt: true, types: [BoolType()]),
          Kwarg(name: "priority", opt: true, types: [`IntType`()]),
          Kwarg(name: "should_fail", opt: true, types: [BoolType()]),
          Kwarg(name: "suite", opt: true, types: [Str(), ListType(types: [Str()])]),
          Kwarg(name: "timeout", opt: true, types: [`IntType`()]),
          Kwarg(name: "verbose", opt: true, types: [BoolType()]),
          Kwarg(name: "workdir", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "bindgen",
        parent: self,
        returnTypes: [CustomTgt()],
        args: [
          Kwarg(name: "c_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(
            name: "input",
            opt: true,
            types: [
              ListType(types: [
                File(), GeneratedList(), BuildTgt(), ExtractedObj(), CustomIdx(), CustomTgt(),
                Str(),
              ])
            ]
          ),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Str(), Inc()])]),
          Kwarg(name: "output", types: [Str()]),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [BuildTgt(), CustomTgt()])]
          ),
        ]
      ),
    ]
  }
}
