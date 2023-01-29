public struct WindowsModule: AbstractObject {
  public let name: String = "windows_module"
  public let parent: AbstractObject? = Module()
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "compile_resources",
        parent: self,
        returnTypes: [ExternalProgram()],
        args: [
          PositionalArgument(
            name: "libs",
            varargs: true,
            types: [Str(), File(), CustomTgt(), CustomIdx()]
          ),
          Kwarg(name: "depends", opt: true, types: [ListType(types: [BuildTgt(), CustomTgt()])]),
          Kwarg(name: "depend_files", opt: true, types: [ListType(types: [Str(), File()])]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Str(), Inc()])]),
          Kwarg(name: "args", opt: true, types: [Str(), ListType(types: [Str()])]),
        ]
      )
    ]
  }
}
