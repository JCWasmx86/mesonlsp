public struct Meson: AbstractObject {
  public let name: String = "meson"
  public let parent: AbstractObject? = nil
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "add_devenv",
        parent: self,
        args: [
          PositionalArgument(
            name: "env",
            types: [
              Env(), Str(), ListType(types: [Str()]), Dict(types: [Str()]),
              Dict(types: [ListType(types: [Str()])]),
            ]
          ), Kwarg(name: "method", types: [Str()]),
          Kwarg(name: "separator", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "add_dist_script",
        parent: self,
        args: [
          PositionalArgument(name: "script_name", types: [Str(), File(), ExternalProgram()]),
          PositionalArgument(
            name: "arg",
            varargs: true,
            opt: true,
            types: [Str(), File(), ExternalProgram()]
          ),
        ]
      ),
      Method(
        name: "add_install_script",
        parent: self,
        args: [
          PositionalArgument(
            name: "script_name",
            types: [Str(), File(), ExternalProgram(), Exe(), CustomTgt(), CustomIdx()]
          ),
          PositionalArgument(
            name: "arg",
            varargs: true,
            opt: true,
            types: [Str(), File(), ExternalProgram(), Exe(), CustomTgt(), CustomIdx()]
          ), Kwarg(name: "install_tag", opt: true, types: [Str()]),
          Kwarg(name: "skip_if_destdir", opt: true, types: [BoolType()]),
        ]
      ),
      Method(
        name: "add_postconf_script",
        parent: self,
        args: [
          PositionalArgument(name: "script_name", types: [Str(), File(), ExternalProgram()]),
          PositionalArgument(
            name: "arg",
            varargs: true,
            opt: true,
            types: [Str(), File(), ExternalProgram()]
          ),
        ]
      ), Method(name: "backend", parent: self, returnTypes: [Str()]),
      Method(name: "build_root", parent: self, returnTypes: [Str()]),
      Method(name: "can_run_host_binaries", parent: self, returnTypes: [BoolType()]),
      Method(name: "current_build_dir", parent: self, returnTypes: [Str()]),
      Method(name: "current_source_dir", parent: self, returnTypes: [Str()]),
      Method(
        name: "get_compiler",
        parent: self,
        returnTypes: [Compiler()],
        args: [
          PositionalArgument(name: "language", types: [Str()]),
          Kwarg(name: "native", opt: true, types: [BoolType()]),
        ]
      ),
      Method(
        name: "get_cross_property",
        parent: self,
        returnTypes: [`Any`()],
        args: [
          PositionalArgument(name: "propname", types: [Str()]),
          PositionalArgument(name: "fallback_value", opt: true, types: [`Any`()]),
        ]
      ),
      Method(
        name: "get_external_property",
        parent: self,
        returnTypes: [`Any`()],
        args: [
          PositionalArgument(name: "propname", types: [Str()]),
          PositionalArgument(name: "fallback_value", opt: true, types: [`Any`()]),
        ]
      ), Method(name: "global_build_root", parent: self, returnTypes: [Str()]),
      Method(name: "global_source_root", parent: self, returnTypes: [Str()]),
      Method(name: "has_exe_wrapper", parent: self, returnTypes: [BoolType()]),
      Method(
        name: "has_external_property",
        parent: self,
        returnTypes: [BoolType()],
        args: [
          PositionalArgument(name: "propname", types: [Str()]),
          Kwarg(name: "native", opt: true, types: [BoolType()]),
        ]
      ),
      Method(
        name: "install_dependency_manifest",
        parent: self,
        args: [PositionalArgument(name: "output_name", types: [Str()])]
      ), Method(name: "is_cross_build", parent: self, returnTypes: [BoolType()]),
      Method(name: "is_subproject", parent: self, returnTypes: [BoolType()]),
      Method(name: "is_unity", parent: self, returnTypes: [BoolType()]),
      Method(
        name: "override_dependency",
        parent: self,
        args: [
          PositionalArgument(name: "name", types: [Str()]),
          PositionalArgument(name: "dep_object", types: [Dep()]),
          Kwarg(name: "native", opt: true, types: [BoolType()]),
          Kwarg(name: "static", opt: true, types: [BoolType()]),
        ]
      ),
      Method(
        name: "override_find_program",
        parent: self,
        args: [
          PositionalArgument(name: "progname", types: [Str()]),
          PositionalArgument(name: "program", types: [Exe(), File(), ExternalProgram()]),
        ]
      ), Method(name: "project_build_root", parent: self, returnTypes: [Str()]),
      Method(name: "project_license", parent: self, returnTypes: [ListType(types: [Str()])]),
      Method(name: "project_license_files", parent: self),
      Method(name: "project_name", parent: self, returnTypes: [Str()]),
      Method(name: "project_source_root", parent: self, returnTypes: [Str()]),
      Method(name: "project_version", parent: self, returnTypes: [Str()]),
      Method(name: "source_root", parent: self, returnTypes: [Str()]),
      Method(name: "version", parent: self, returnTypes: [Str()]),
    ]
  }
}
