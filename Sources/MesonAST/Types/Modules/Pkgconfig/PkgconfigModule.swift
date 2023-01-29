public struct PkgconfigModule: AbstractObject {
  public let name: String = "pkgconfig_module"
  public let parent: AbstractObject? = Module()
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "generate",
        parent: self,
        returnTypes: [ExternalProgram()],
        args: [
          PositionalArgument(name: "libs", opt: true, types: [Lib()]),
          Kwarg(
            name: "d_module_versions",
            opt: true,
            types: [ListType(types: [Str(), `IntType`()])]
          ), Kwarg(name: "install_dir", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "conflicts", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dataonly", opt: true, types: [BoolType()]),
          Kwarg(name: "description", opt: true, types: [Str()]),
          Kwarg(name: "extra_cflags", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "filebase", opt: true, types: [Str()]),
          Kwarg(name: "subdirs", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "name", opt: true, types: [Str()]),
          Kwarg(name: "url", opt: true, types: [Str()]),
          Kwarg(name: "version", opt: true, types: [Str()]),
          Kwarg(
            name: "variables",
            opt: true,
            types: [ListType(types: [Str()]), Dict(types: [Str()])]
          ),
          Kwarg(
            name: "unescaped_variables",
            opt: true,
            types: [ListType(types: [Str()]), Dict(types: [Str()])]
          ),
          Kwarg(
            name: "uninstalled_variables",
            opt: true,
            types: [ListType(types: [Str()]), Dict(types: [Str()])]
          ),
          Kwarg(
            name: "unescaped_uninstalled_variables",
            opt: true,
            types: [ListType(types: [Str()]), Dict(types: [Str()])]
          ),
          Kwarg(
            name: "libraries",
            opt: true,
            types: [ListType(types: [Str(), Dep(), Lib(), CustomTgt(), CustomIdx()])]
          ),
          Kwarg(
            name: "libraries_private",
            opt: true,
            types: [ListType(types: [Str(), Dep(), Lib(), CustomTgt(), CustomIdx()])]
          ), Kwarg(name: "requires", opt: true, types: [ListType(types: [Str(), Dep(), Lib()])]),
          Kwarg(
            name: "requires_private",
            opt: true,
            types: [ListType(types: [Str(), Dep(), Lib()])]
          ),
        ]
      )
    ]
  }
}
