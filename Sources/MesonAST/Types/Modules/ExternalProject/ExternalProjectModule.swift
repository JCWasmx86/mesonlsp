public struct ExternalProjectModule: AbstractObject {
  public let name: String = "external_project_module"
  public let parent: AbstractObject? = Module()
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "add_project",
        parent: self,
        returnTypes: [ExternalProject()],
        args: [
          PositionalArgument(name: "script", types: [Str()]),
          Kwarg(name: "configure_options", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cross_configure_options", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "verbose", opt: true, types: [BoolType()]),
          Kwarg(
            name: "env",
            opt: true,
            types: [Env(), ListType(types: [Str()]), Dict(types: [Str()])]
          ),
          Kwarg(name: "depends", opt: true, types: [ListType(types: [BuildTgt(), CustomTgt()])]),
        ]
      )
    ]
  }
}
