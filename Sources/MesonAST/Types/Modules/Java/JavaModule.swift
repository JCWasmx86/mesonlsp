public struct JavaModule: AbstractObject {
  public let name: String = "java_module"
  public let parent: AbstractObject? = Module()
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "generate_native_header",
        parent: self,
        returnTypes: [CustomTgt()],
        args: [
          PositionalArgument(
            name: "files",
            varargs: true,
            opt: true,
            types: [Str(), File(), Tgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "package", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "generate_native_headers",
        parent: self,
        returnTypes: [CustomTgt()],
        args: [
          PositionalArgument(
            name: "files",
            varargs: true,
            opt: true,
            types: [Str(), File(), Tgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "classes", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "package", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "native_headers",
        parent: self,
        returnTypes: [CustomTgt()],
        args: [
          PositionalArgument(
            name: "files",
            varargs: true,
            opt: true,
            types: [Str(), File(), Tgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "classes", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "package", opt: true, types: [Str()]),
        ]
      ),
    ]
  }
}
