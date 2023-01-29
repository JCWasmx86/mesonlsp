public struct CMakeModule: AbstractObject {
  public let name: String = "cmake_module"
  public let parent: AbstractObject? = Module()
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "subproject",
        parent: self,
        returnTypes: [CMakeSubproject()],
        args: [
          PositionalArgument(name: "subproject_name", types: [Str()]),
          Kwarg(name: "options", opt: true, types: [CMakeSubprojectOptions()]),
          Kwarg(name: "required", opt: true, types: [BoolType(), Feature()]),
          Kwarg(name: "cmake_options", opt: true, types: [ListType(types: [Str()])]),
        ]
      ),
      Method(
        name: "subproject_options",
        parent: self,
        returnTypes: [CMakeSubprojectOptions()],
        args: []
      ),
      Method(
        name: "write_basic_package_version_file",
        parent: self,
        returnTypes: [],
        args: [
          Kwarg(name: "name", types: [Str()]), Kwarg(name: "version", types: [Str()]),
          Kwarg(name: "compatibility", opt: true, types: [Str()]),
          Kwarg(name: "arch_independent", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "configure_package_config_file",
        parent: self,
        returnTypes: [],
        args: [
          Kwarg(name: "name", types: [Str()]), Kwarg(name: "input", types: [Str(), File()]),
          Kwarg(name: "configuration", types: [CfgData()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
        ]
      ),
    ]
  }
}
