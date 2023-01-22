public struct PythonModule: AbstractObject {
  public let name: String = "python_module"
  public let parent: AbstractObject? = Module()
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "find_installation", parent: self, returnTypes: [PythonInstallation()],
        args: [
          PositionalArgument(name: "name_or_path", opt: true, types: [Str()]),
          Kwarg(name: "required", opt: true, types: [BoolType()]),
          Kwarg(name: "disabler", opt: true, types: [BoolType()]),
          Kwarg(name: "modules", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "pure", opt: true, types: [BoolType()]),
        ])
    ]
  }
}
