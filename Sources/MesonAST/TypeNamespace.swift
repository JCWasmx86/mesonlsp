public class TypeNamespace {
  public var functions: [Function] = []
  public var types: [String: Type]

  public init() {
    types = [
      "any": `Any`(),
      "bool": BoolType(),
      "build_machine": BuildMachine(),
      "dict": Dict(types: []),
      "host_machine": HostMachine(),
      "int": IntType(),
      "list": ListType(types: []),
      "meson": Meson(),
      "str": Str(),
      "target_machine": TargetMachine(),
      "void": `Void`(),
      "alias_tgt": AliasTgt(),
      "both_libs": BothLibs(),
      "build_tgt": BuildTgt(),
      "cfg_data": CfgData(),
      "compiler": Compiler(),
      "custom_idx": CustomIdx(),
      "custom_tgt": CustomTgt(),
      "dep": Dep(),
      "disabler": Disabler(),
      "env": Env(),
      "exe": Exe(),
      "external_program": ExternalProgram(),
      "extracted_obj": ExtractedObj(),
      "feature": Feature(),
      "file": File(),
      "generated_list": GeneratedList(),
      "inc": Inc(),
      "jar": Jar(),
      "lib": Lib(),
      "module": Module(),
      "range": Range(),
      "runresult": RunResult(),
      "run_tgt": RunTgt(),
      "structured_src": StructuredSrc(),
      "subproject": Subproject(),
      "tgt": Tgt(),
    ]
    self.functions = [
      Function(name: "add_global_arguments"),
      Function(name: "add_global_link_arguments"),
      Function(name: "add_languages"),
      Function(name: "add_project_arguments"),
      Function(name: "add_project_dependencies"),
      Function(name: "add_project_link_arguments"),
      Function(name: "add_test_setup"),
      Function(
        name: "alias_target",
        returnTypes: [
          AliasTgt()
        ]),
      Function(name: "assert"),
      Function(name: "benchmark"),
      Function(
        name: "both_libraries",
        returnTypes: [
          BothLibs()
        ]),
      Function(
        name: "build_target",
        returnTypes: [
          BuildTgt()
        ]),
      Function(
        name: "configuration_data",
        returnTypes: [
          CfgData()
        ]),
      Function(
        name: "configure_file",
        returnTypes: [
          File()
        ]),
      Function(
        name: "custom_target",
        returnTypes: [
          CustomTgt()
        ]),
      Function(name: "debug"),
      Function(
        name: "declare_dependency",
        returnTypes: [
          Dep()
        ]),
      Function(
        name: "dependency",
        returnTypes: [
          Dep()
        ]),
      Function(
        name: "disabler",
        returnTypes: [
          Disabler()
        ]),
      Function(
        name: "environment",
        returnTypes: [
          Env()
        ]),
      Function(name: "error"),
      Function(
        name: "executable",
        returnTypes: [
          Exe()
        ]),
      Function(
        name: "files",
        returnTypes: [
          ListType(types: [File()])
        ]),
      Function(
        name: "find_program",
        returnTypes: [
          ExternalProgram()
        ]),
      Function(
        name: "generator",
        returnTypes: [
          Generator()
        ]),
      Function(
        name: "get_option",
        returnTypes: [
          Str(),
          `IntType`(),
          BoolType(),
          Feature(),
          ListType(types: [
            Str(),
            `IntType`(),
            BoolType(),
          ]),
        ]),
      Function(
        name: "get_variable",
        returnTypes: [
          `Any`()
        ]),
      Function(
        name: "import",
        returnTypes: [
          Module()
        ]),
      Function(
        name: "include_directories",
        returnTypes: [
          Inc()
        ]),
      Function(name: "install_data"),
      Function(name: "install_emptydir"),
      Function(name: "install_headers"),
      Function(name: "install_man"),
      Function(name: "install_subdir"),
      Function(name: "install_symlink"),
      Function(
        name: "is_disabler",
        returnTypes: [
          BoolType()
        ]),
      Function(
        name: "is_variable",
        returnTypes: [
          BoolType()
        ]),
      Function(
        name: "jar",
        returnTypes: [
          Jar()
        ]),
      Function(
        name: "join_paths",
        returnTypes: [
          Str()
        ]),
      Function(
        name: "library",
        returnTypes: [
          Lib()
        ]),
      Function(name: "message"),
      Function(name: "project"),
      Function(
        name: "range",
        returnTypes: [
          Range()
        ]),
      Function(
        name: "run_command",
        returnTypes: [
          RunResult()
        ]),
      Function(
        name: "run_target",
        returnTypes: [
          RunTgt()
        ]),
      Function(name: "set_variable"),
      Function(
        name: "shared_library",
        returnTypes: [
          Lib()
        ]),
      Function(
        name: "shared_module",
        returnTypes: [
          BuildTgt()
        ]),
      Function(
        name: "static_library",
        returnTypes: [
          Lib()
        ]),
      Function(
        name: "structured_sources",
        returnTypes: [
          StructuredSrc()
        ]),
      Function(name: "subdir"),
      Function(name: "subdir_done"),
      Function(
        name: "subproject",
        returnTypes: [
          Subproject()
        ]),
      Function(name: "summary"),
      Function(name: "test"),
      Function(name: "unset_variable"),
      Function(
        name: "vcs_tag",
        returnTypes: [
          CustomTgt()
        ]),
      Function(name: "warning"),
    ]
  }

  public func lookupFunction(name: String) -> Function? {
    for f in self.functions {
      if f.name == name {
        return f
      }
    }
    return nil
  }
}
