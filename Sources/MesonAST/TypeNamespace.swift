public class TypeNamespace {
  public var functions: [Function] = []
  public var types: [String: Type]

  public init() {
    types = [
      "any": `Any`(), "bool": BoolType(), "build_machine": BuildMachine(), "dict": Dict(types: []),
      "host_machine": HostMachine(), "int": IntType(), "list": ListType(types: []),
      "meson": Meson(), "str": Str(), "target_machine": TargetMachine(), "void": `Void`(),
      "alias_tgt": AliasTgt(), "both_libs": BothLibs(), "build_tgt": BuildTgt(),
      "cfg_data": CfgData(), "compiler": Compiler(), "custom_idx": CustomIdx(),
      "custom_tgt": CustomTgt(), "dep": Dep(), "disabler": Disabler(), "env": Env(), "exe": Exe(),
      "external_program": ExternalProgram(), "extracted_obj": ExtractedObj(), "feature": Feature(),
      "file": File(), "generated_list": GeneratedList(), "inc": Inc(), "jar": Jar(), "lib": Lib(),
      "module": Module(), "range": RangeType(), "runresult": RunResult(), "run_tgt": RunTgt(),
      "structured_src": StructuredSrc(), "subproject": Subproject(), "tgt": Tgt(),
      "cmake_module": CMakeModule(), "cmake_subproject": CMakeSubproject(),
      "cmake_subprojectoptions": CMakeSubprojectOptions(), "cmake_tgt": CMakeTarget(),
      "fs_module": FSModule(), "i18n_module": I18nModule(), "gnome_module": GNOMEModule(),
      "rust_module": RustModule(), "python_module": PythonModule(),
      "python_installatioN": PythonInstallation(),
    ]
    self.functions = [
      Function(
        name: "add_global_arguments",
        args: [
          PositionalArgument(name: "arg", varargs: true, opt: true, types: [Str()]),
          Kwarg(name: "language", types: [ListType(types: [Str()])]),
          Kwarg(name: "native", opt: true, types: [BoolType()]),
        ]),
      Function(
        name: "add_global_link_arguments",
        args: [
          PositionalArgument(name: "arg", varargs: true, opt: true, types: [Str()]),
          Kwarg(name: "language", types: [ListType(types: [Str()])]),
          Kwarg(name: "native", opt: true, types: [BoolType()]),
        ]),
      Function(
        name: "add_languages", returnTypes: [BoolType()],
        args: [
          PositionalArgument(name: "language", varargs: true, opt: true, types: [Str()]),
          Kwarg(name: "native", opt: true, types: [BoolType()]),
          Kwarg(name: "required", opt: true, types: [BoolType()]),
        ]),
      Function(
        name: "add_project_arguments",
        args: [
          PositionalArgument(name: "arg", varargs: true, opt: true, types: [Str()]),
          Kwarg(name: "language", types: [ListType(types: [Str()])]),
          Kwarg(name: "native", opt: true, types: [BoolType()]),
        ]),
      Function(
        name: "add_project_dependencies",
        args: [
          PositionalArgument(name: "dependency", varargs: true, opt: true, types: [Dep()]),
          Kwarg(name: "language", types: [ListType(types: [Str()])]),
          Kwarg(name: "native", opt: true, types: [BoolType()]),
        ]),
      Function(
        name: "add_project_link_arguments",
        args: [
          PositionalArgument(name: "arg", varargs: true, opt: true, types: [Str()]),
          Kwarg(name: "language", types: [ListType(types: [Str()])]),
          Kwarg(name: "native", opt: true, types: [BoolType()]),
        ]),
      Function(
        name: "add_test_setup",
        args: [
          PositionalArgument(name: "name", types: [Str()]),
          Kwarg(
            name: "env", opt: true, types: [Env(), ListType(types: [Str()]), Dict(types: [Str()])]),
          Kwarg(name: "exclude_suites", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(
            name: "exe_wrapper", opt: true, types: [ListType(types: [Str(), ExternalProgram()])]),
          Kwarg(name: "gdb", opt: true, types: [BoolType()]),
          Kwarg(name: "is_default", opt: true, types: [BoolType()]),
          Kwarg(name: "timeout_multiplier", opt: true, types: [`IntType`()]),
        ]),
      Function(
        name: "alias_target", returnTypes: [AliasTgt()],
        args: [
          PositionalArgument(name: "target_name", types: [Str()]),
          PositionalArgument(name: "dep", varargs: true, opt: false, types: [Dep()]),
        ]),
      Function(
        name: "assert",
        args: [
          PositionalArgument(name: "condition", types: [BoolType()]),
          PositionalArgument(name: "message", opt: true, types: [Str()]),
        ]),
      Function(
        name: "benchmark",
        args: [
          PositionalArgument(name: "name", types: [Str()]),
          PositionalArgument(name: "executable", types: [Exe(), Jar(), ExternalProgram(), File()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str(), File(), Tgt()])]),
          Kwarg(name: "depends", opt: true, types: [ListType(types: [BuildTgt(), CustomTgt()])]),
          Kwarg(
            name: "env", opt: true, types: [Str(), ListType(types: [Str()]), Dict(types: [Str()])]),
          Kwarg(name: "priority", opt: true, types: [`IntType`()]),
          Kwarg(name: "protocol", opt: true, types: [Str()]),
          Kwarg(name: "should_fail", opt: true, types: [BoolType()]),
          Kwarg(name: "suite", opt: true, types: [Str(), ListType(types: [Str()])]),
          Kwarg(name: "timeout", opt: true, types: [`IntType`()]),
          Kwarg(name: "verbose", opt: true, types: [BoolType()]),
          Kwarg(name: "workdir", opt: true, types: [Str()]),
        ]),
      Function(
        name: "both_libraries", returnTypes: [BothLibs()],
        args: [
          PositionalArgument(name: "target_name", types: [Str()]),
          PositionalArgument(
            name: "source", varargs: true, opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]),
          Kwarg(name: "c_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cpp_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cs_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "d_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "fortran_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "java_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "objc_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "objcpp_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "rust_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "vala_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cython_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "nasm_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "masm_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "c_pch", opt: true, types: [Str()]),
          Kwarg(name: "cpp_pch", opt: true, types: [Str()]),
          Kwarg(name: "build_by_default", opt: true, types: [BoolType()]),
          Kwarg(name: "build_rpath", opt: true, types: [Str()]),
          Kwarg(name: "d_debug", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "d_import_dirs", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(
            name: "d_module_versions", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "d_unittest", opt: true, types: [BoolType()]),
          Kwarg(
            name: "darwin_versions", opt: true,
            types: [Str(), `IntType`(), ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()])]),
          Kwarg(name: "extra_files", opt: true, types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "gnu_symbol_visibility", opt: true, types: [Str()]),
          Kwarg(name: "gui_app", opt: true, types: [BoolType()]),
          Kwarg(name: "implicit_include_directories", opt: true, types: [BoolType()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Str(), Inc()])]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "install_rpath", opt: true, types: [Str()]),
          Kwarg(name: "install_tag", opt: true, types: [Str()]),
          Kwarg(name: "link_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "link_depends", opt: true, types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "link_language", opt: true, types: [Str()]),
          Kwarg(
            name: "link_whole", opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]),
          Kwarg(
            name: "link_with", opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]),
          Kwarg(name: "name_prefix", opt: true, types: [Str(), ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [Str(), ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: [BoolType()]),
          Kwarg(
            name: "objects", opt: true, types: [ListType(types: [ExtractedObj(), File(), Str()])]),
          Kwarg(name: "override_options", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "pic", opt: true, types: [BoolType()]),
          Kwarg(name: "prelink", opt: true, types: [BoolType()]),
          Kwarg(name: "rust_crate_type", opt: true, types: [Str()]),
          Kwarg(
            name: "sources", opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList(), StructuredSrc()]),
          Kwarg(name: "soversion", opt: true, types: [Str(), `IntType`()]),
          Kwarg(name: "version", opt: true, types: [Str()]),
          Kwarg(
            name: "vs_module_defs", opt: true, types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "win_subsystem", opt: true, types: [Str()]),
        ]),
      Function(
        name: "build_target", returnTypes: [BuildTgt()],
        args: [
          PositionalArgument(name: "target_name", types: [Str()]),
          PositionalArgument(
            name: "source", varargs: true, opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]),
          Kwarg(name: "c_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cpp_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cs_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "d_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "fortran_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "java_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "objc_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "objcpp_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "rust_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "vala_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cython_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "nasm_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "masm_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "c_pch", opt: true, types: [Str()]),
          Kwarg(name: "cpp_pch", opt: true, types: [Str()]),
          Kwarg(name: "build_by_default", opt: true, types: [BoolType()]),
          Kwarg(name: "build_rpath", opt: true, types: [Str()]),
          Kwarg(name: "d_debug", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "d_import_dirs", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(
            name: "d_module_versions", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "d_unittest", opt: true, types: [BoolType()]),
          Kwarg(
            name: "darwin_versions", opt: true,
            types: [Str(), `IntType`(), ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()])]),
          Kwarg(name: "extra_files", opt: true, types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "gnu_symbol_visibility", opt: true, types: [Str()]),
          Kwarg(name: "gui_app", opt: true, types: [BoolType()]),
          Kwarg(name: "implib", opt: true, types: [BoolType(), Str()]),
          Kwarg(name: "implicit_include_directories", opt: true, types: [BoolType()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Str(), Inc()])]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "install_rpath", opt: true, types: [Str()]),
          Kwarg(name: "install_tag", opt: true, types: [Str()]),
          Kwarg(name: "java_resources", opt: true, types: [StructuredSrc()]),
          Kwarg(name: "link_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "link_depends", opt: true, types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "link_language", opt: true, types: [Str()]),
          Kwarg(
            name: "link_whole", opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]),
          Kwarg(
            name: "link_with", opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]),
          Kwarg(name: "main_class", opt: true, types: [Str()]),
          Kwarg(name: "name_prefix", opt: true, types: [Str(), ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [Str(), ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: [BoolType()]),
          Kwarg(
            name: "objects", opt: true, types: [ListType(types: [ExtractedObj(), File(), Str()])]),
          Kwarg(name: "override_options", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "pic", opt: true, types: [BoolType()]),
          Kwarg(name: "pie", opt: true, types: [BoolType()]),
          Kwarg(name: "prelink", opt: true, types: [BoolType()]),
          Kwarg(name: "rust_crate_type", opt: true, types: [Str()]),
          Kwarg(
            name: "sources", opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList(), StructuredSrc()]),
          Kwarg(name: "soversion", opt: true, types: [Str(), `IntType`()]),
          Kwarg(name: "version", opt: true, types: [Str()]),
          Kwarg(
            name: "vs_module_defs", opt: true, types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "win_subsystem", opt: true, types: [Str()]),
        ]),
      Function(
        name: "configuration_data", returnTypes: [CfgData()],
        args: [
          PositionalArgument(
            name: "data", opt: true, types: [Dict(types: [Str(), BoolType(), `IntType`()])])
        ]),
      Function(
        name: "configure_file", returnTypes: [File()],
        args: [
          Kwarg(name: "capture", opt: true, types: [BoolType()]),
          Kwarg(name: "command", opt: true, types: [ListType(types: [Str(), File()])]),
          Kwarg(
            name: "configuration", opt: true,
            types: [Dict(types: [Str(), `IntType`(), BoolType()]), CfgData()]),
          Kwarg(name: "copy", opt: true, types: [BoolType()]),
          Kwarg(name: "depfile", opt: true, types: [Str()]),
          Kwarg(name: "encoding", opt: true, types: [Str()]),
          Kwarg(name: "format", opt: true, types: [Str()]),
          Kwarg(name: "input", types: [Str(), File()]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "install_tag", opt: true, types: [Str()]),
          Kwarg(name: "output", types: [Str()]),
          Kwarg(name: "output_format", opt: true, types: [Str()]),
        ]),
      Function(
        name: "custom_target", returnTypes: [CustomTgt()],
        args: [
          PositionalArgument(name: "name", opt: true, types: [Str()]),
          Kwarg(name: "build_always", opt: true, types: [BoolType()]),
          Kwarg(name: "build_always_stale", opt: true, types: [BoolType()]),
          Kwarg(name: "build_by_default", opt: true, types: [BoolType()]),
          Kwarg(name: "capture", opt: true, types: [BoolType()]),
          Kwarg(
            name: "command", types: [ListType(types: [Str(), File(), Exe(), ExternalProgram()])]),
          Kwarg(name: "console", opt: true, types: [BoolType()]),
          Kwarg(name: "depend_files", opt: true, types: [ListType(types: [Str(), File()])]),
          Kwarg(name: "depends", opt: true, types: [ListType(types: [BuildTgt(), CustomTgt()])]),
          Kwarg(name: "depfile", opt: true, types: [Str()]),
          Kwarg(
            name: "env", opt: true, types: [Env(), ListType(types: [Str()]), Dict(types: [Str()])]),
          Kwarg(name: "feed", opt: true, types: [BoolType()]),
          Kwarg(name: "input", types: [ListType(types: [Str(), File()])]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "install_tag", opt: true, types: [Str()]),
          Kwarg(name: "output", types: [ListType(types: [Str()])]),
        ]),
      Function(
        name: "debug",
        args: [
          PositionalArgument(
            name: "message",
            types: [
              Str(), `IntType`(), BoolType(), ListType(types: [Str(), `IntType`(), BoolType()]),
              Dict(types: [Str(), `IntType`(), BoolType()]),
            ]),
          PositionalArgument(
            name: "msg", varargs: true, opt: true,
            types: [
              Str(), `IntType`(), BoolType(), ListType(types: [Str(), `IntType`(), BoolType()]),
              Dict(types: [Str(), `IntType`(), BoolType()]),
            ]),
        ]),
      Function(
        name: "declare_dependency", returnTypes: [Dep()],
        args: [
          Kwarg(name: "compile_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "d_import_dirs", opt: true, types: [ListType(types: [Str(), Inc()])]),
          Kwarg(
            name: "d_module_versions", opt: true,
            types: [Str(), `IntType`(), ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()])]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Str(), Inc()])]),
          Kwarg(name: "link_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "link_whole", opt: true, types: [ListType(types: [Lib()])]),
          Kwarg(name: "link_with", opt: true, types: [ListType(types: [Lib()])]),
          Kwarg(name: "objects", opt: true, types: [ListType(types: [ExtractedObj()])]),
          Kwarg(
            name: "sources", opt: true,
            types: [ListType(types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()])]),
          Kwarg(
            name: "variables", opt: true, types: [ListType(types: [Str()]), Dict(types: [Str()])]),
          Kwarg(name: "version", opt: true, types: [Str()]),
        ]),
      Function(
        name: "dependency", returnTypes: [Dep()],
        args: [
          PositionalArgument(name: "names", varargs: true, types: [Str()]),
          Kwarg(name: "allow_fallback", opt: true, types: [BoolType()]),
          Kwarg(name: "default_options", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "disabler", opt: true, types: [BoolType()]),
          Kwarg(name: "fallback", opt: true, types: [Str(), ListType(types: [Str()])]),
          Kwarg(name: "include_type", opt: true, types: [Str()]),
          Kwarg(name: "language", opt: true, types: [Str()]),
          Kwarg(name: "method", opt: true, types: [Str()]),
          Kwarg(name: "native", opt: true, types: [BoolType()]),
          Kwarg(name: "not_found_message", opt: true, types: [Str()]),
          Kwarg(name: "required", opt: true, types: [BoolType(), Feature()]),
          Kwarg(name: "static", opt: true, types: [BoolType()]),
          Kwarg(name: "version", opt: true, types: [Str()]),
        ]), Function(name: "disabler", returnTypes: [Disabler()]),
      Function(
        name: "environment", returnTypes: [Env()],
        args: [
          PositionalArgument(
            name: "env", opt: true,
            types: [
              Str(), ListType(types: [Str()]), Dict(types: [Str()]),
              Dict(types: [ListType(types: [Str()])]),
            ]), Kwarg(name: "method", opt: true, types: [Str()]),
          Kwarg(name: "separator", opt: true, types: [Str()]),
        ]),
      Function(
        name: "error",
        args: [
          PositionalArgument(name: "message", types: [Str()]),
          PositionalArgument(name: "msg", varargs: true, opt: true, types: [Str()]),
        ]),
      Function(
        name: "executable", returnTypes: [Exe()],
        args: [
          PositionalArgument(name: "target_name", types: [Str()]),
          PositionalArgument(
            name: "source", varargs: true, opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]),
          Kwarg(name: "c_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cpp_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cs_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "d_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "fortran_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "java_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "objc_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "objcpp_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "rust_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "vala_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cython_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "nasm_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "masm_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "c_pch", opt: true, types: [Str()]),
          Kwarg(name: "cpp_pch", opt: true, types: [Str()]),
          Kwarg(name: "build_by_default", opt: true, types: [BoolType()]),
          Kwarg(name: "build_rpath", opt: true, types: [Str()]),
          Kwarg(name: "d_debug", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "d_import_dirs", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(
            name: "d_module_versions", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "d_unittest", opt: true, types: [BoolType()]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()])]),
          Kwarg(name: "export_dynamic", opt: true, types: [BoolType()]),
          Kwarg(name: "extra_files", opt: true, types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "gnu_symbol_visibility", opt: true, types: [Str()]),
          Kwarg(name: "gui_app", opt: true, types: [BoolType()]),
          Kwarg(name: "implib", opt: true, types: [BoolType(), Str()]),
          Kwarg(name: "implicit_include_directories", opt: true, types: [BoolType()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Str(), Inc()])]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "install_rpath", opt: true, types: [Str()]),
          Kwarg(name: "install_tag", opt: true, types: [Str()]),
          Kwarg(name: "link_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "link_depends", opt: true, types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "link_language", opt: true, types: [Str()]),
          Kwarg(
            name: "link_whole", opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]),
          Kwarg(
            name: "link_with", opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]),
          Kwarg(name: "name_prefix", opt: true, types: [Str(), ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [Str(), ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: [BoolType()]),
          Kwarg(
            name: "objects", opt: true, types: [ListType(types: [ExtractedObj(), File(), Str()])]),
          Kwarg(name: "override_options", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "pie", opt: true, types: [BoolType()]),
          Kwarg(name: "rust_crate_type", opt: true, types: [Str()]),
          Kwarg(
            name: "sources", opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList(), StructuredSrc()]),
          Kwarg(name: "win_subsystem", opt: true, types: [Str()]),
        ]),
      Function(
        name: "files", returnTypes: [ListType(types: [File()])],
        args: [PositionalArgument(name: "file", varargs: true, opt: true, types: [Str()])]),
      Function(
        name: "find_program", returnTypes: [ExternalProgram()],
        args: [
          PositionalArgument(name: "program_name", types: [Str(), File()]),
          PositionalArgument(name: "fallback", varargs: true, opt: true, types: [Str(), File()]),
          Kwarg(name: "dirs", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "disabler", opt: true, types: [BoolType()]),
          Kwarg(name: "native", opt: true, types: [BoolType()]),
          Kwarg(name: "required", opt: true, types: [BoolType(), Feature()]),
          Kwarg(name: "version", opt: true, types: [Str()]),
        ]),
      Function(
        name: "generator", returnTypes: [Generator()],
        args: [
          PositionalArgument(name: "exe", types: [Exe(), ExternalProgram()]),
          Kwarg(name: "arguments", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "capture", opt: true, types: [BoolType()]),
          Kwarg(name: "depends", opt: true, types: [ListType(types: [BuildTgt(), CustomTgt()])]),
          Kwarg(name: "depfile", opt: true, types: [Str()]),
          Kwarg(name: "output", opt: true, types: [ListType(types: [Str()])]),
        ]),
      Function(
        name: "get_option",
        returnTypes: [
          Str(), `IntType`(), BoolType(), Feature(),
          ListType(types: [Str(), `IntType`(), BoolType()]),
        ], args: [PositionalArgument(name: "option_name", types: [Str()])]),
      Function(
        name: "get_variable", returnTypes: [`Any`()],
        args: [
          PositionalArgument(name: "variable_name", types: [Str()]),
          PositionalArgument(name: "default", opt: true, types: [`Any`()]),
        ]),
      Function(
        name: "import", returnTypes: [Module()],
        args: [
          PositionalArgument(name: "module_name", types: [Str()]),
          Kwarg(name: "module_name", opt: true, types: [BoolType()]),
          Kwarg(name: "required", opt: true, types: [BoolType(), Feature()]),
        ]),
      Function(
        name: "include_directories", returnTypes: [Inc()],
        args: [
          PositionalArgument(name: "includes", varargs: true, opt: true, types: [Str()]),
          Kwarg(name: "is_system", opt: true, types: [BoolType()]),
        ]),
      Function(
        name: "install_data",
        args: [
          PositionalArgument(name: "file", varargs: true, opt: true, types: [Str(), File()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "install_tag", opt: true, types: [Str()]),
          Kwarg(name: "preserve_path", opt: true, types: [BoolType()]),
          Kwarg(name: "rename", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "sources", opt: true, types: [ListType(types: [File(), Str()])]),
        ]),
      Function(
        name: "install_emptydir",
        args: [
          PositionalArgument(name: "dirpath", varargs: true, opt: true, types: [Str()]),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "install_tag", opt: true, types: [Str()]),
        ]),
      Function(
        name: "install_headers",
        args: [
          PositionalArgument(name: "file", varargs: true, opt: true, types: [Str(), File()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "preserve_path", opt: true, types: [BoolType()]),
          Kwarg(name: "subdir", opt: true, types: [Str()]),
        ]),
      Function(
        name: "install_man",
        args: [
          PositionalArgument(name: "file", varargs: true, opt: true, types: [Str(), File()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "locale", opt: true, types: [Str()]),
        ]),
      Function(
        name: "install_subdir",
        args: [
          PositionalArgument(name: "subdir_name", types: [Str()]),
          Kwarg(name: "exclude_directories", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "exclude_files", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "install_tag", opt: true, types: [Str()]),
          Kwarg(name: "strip_directory", opt: true, types: [BoolType()]),
        ]),
      Function(
        name: "install_symlink",
        args: [
          PositionalArgument(name: "link_name", types: [Str()]),
          Kwarg(name: "install_dir", types: [Str()]),
          Kwarg(name: "install_tag", opt: true, types: [Str()]),
          Kwarg(name: "pointing_to", types: [Str()]),
        ]),
      Function(
        name: "is_disabler", returnTypes: [BoolType()],
        args: [PositionalArgument(name: "var", types: [`Any`()])]),
      Function(
        name: "is_variable", returnTypes: [BoolType()],
        args: [PositionalArgument(name: "var", types: [BoolType()])]),
      Function(
        name: "jar", returnTypes: [Jar()],
        args: [
          PositionalArgument(name: "target_name", types: [Str()]),
          PositionalArgument(
            name: "source", varargs: true, opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]),
          Kwarg(name: "c_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cpp_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cs_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "d_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "fortran_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "java_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "objc_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "objcpp_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "rust_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "vala_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cython_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "nasm_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "masm_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "c_pch", opt: true, types: [Str()]),
          Kwarg(name: "cpp_pch", opt: true, types: [Str()]),
          Kwarg(name: "build_by_default", opt: true, types: [BoolType()]),
          Kwarg(name: "build_rpath", opt: true, types: [Str()]),
          Kwarg(name: "d_debug", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "d_import_dirs", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(
            name: "d_module_versions", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "d_unittest", opt: true, types: [BoolType()]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()])]),
          Kwarg(name: "extra_files", opt: true, types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "gnu_symbol_visibility", opt: true, types: [Str()]),
          Kwarg(name: "gui_app", opt: true, types: [BoolType()]),
          Kwarg(name: "implicit_include_directories", opt: true, types: [BoolType()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Str(), Inc()])]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "install_rpath", opt: true, types: [Str()]),
          Kwarg(name: "install_tag", opt: true, types: [Str()]),
          Kwarg(name: "java_resources", opt: true, types: [StructuredSrc()]),
          Kwarg(name: "link_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "link_depends", opt: true, types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "link_language", opt: true, types: [Str()]),
          Kwarg(
            name: "link_whole", opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]),
          Kwarg(
            name: "link_with", opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]),
          Kwarg(name: "main_class", opt: true, types: [Str()]),
          Kwarg(name: "name_prefix", opt: true, types: [Str(), ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [Str(), ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: [BoolType()]),
          Kwarg(
            name: "objects", opt: true, types: [ListType(types: [ExtractedObj(), File(), Str()])]),
          Kwarg(name: "override_options", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "rust_crate_type", opt: true, types: [Str()]),
          Kwarg(
            name: "sources", opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList(), StructuredSrc()]),
          Kwarg(name: "win_subsystem", opt: true, types: [Str()]),
        ]),
      Function(
        name: "join_paths", returnTypes: [Str()],
        args: [PositionalArgument(name: "part", varargs: true, types: [Str()])]),
      Function(
        name: "library", returnTypes: [Lib()],
        args: [
          PositionalArgument(name: "target_name", types: [Str()]),
          PositionalArgument(
            name: "source", varargs: true, opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]),
          Kwarg(name: "c_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cpp_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cs_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "d_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "fortran_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "java_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "objc_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "objcpp_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "rust_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "vala_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cython_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "nasm_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "masm_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "c_pch", opt: true, types: [Str()]),
          Kwarg(name: "cpp_pch", opt: true, types: [Str()]),
          Kwarg(name: "build_by_default", opt: true, types: [BoolType()]),
          Kwarg(name: "build_rpath", opt: true, types: [Str()]),
          Kwarg(name: "d_debug", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "d_import_dirs", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(
            name: "d_module_versions", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "d_unittest", opt: true, types: [BoolType()]),
          Kwarg(
            name: "darwin_versions", opt: true,
            types: [Str(), `IntType`(), ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()])]),
          Kwarg(name: "extra_files", opt: true, types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "gnu_symbol_visibility", opt: true, types: [Str()]),
          Kwarg(name: "gui_app", opt: true, types: [BoolType()]),
          Kwarg(name: "implicit_include_directories", opt: true, types: [BoolType()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Str(), Inc()])]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "install_rpath", opt: true, types: [Str()]),
          Kwarg(name: "install_tag", opt: true, types: [Str()]),
          Kwarg(name: "link_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "link_depends", opt: true, types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "link_language", opt: true, types: [Str()]),
          Kwarg(
            name: "link_whole", opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]),
          Kwarg(
            name: "link_with", opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]),
          Kwarg(name: "name_prefix", opt: true, types: [Str(), ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [Str(), ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: [BoolType()]),
          Kwarg(
            name: "objects", opt: true, types: [ListType(types: [ExtractedObj(), File(), Str()])]),
          Kwarg(name: "override_options", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "pic", opt: true, types: [BoolType()]),
          Kwarg(name: "prelink", opt: true, types: [BoolType()]),
          Kwarg(name: "rust_crate_type", opt: true, types: [Str()]),
          Kwarg(
            name: "sources", opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList(), StructuredSrc()]),
          Kwarg(name: "soversion", opt: true, types: [Str(), `IntType`()]),
          Kwarg(name: "version", opt: true, types: [Str()]),
          Kwarg(
            name: "vs_module_defs", opt: true, types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "win_subsystem", opt: true, types: [Str()]),
        ]),
      Function(
        name: "message",
        args: [
          PositionalArgument(
            name: "message",
            types: [
              Str(), `IntType`(), BoolType(), ListType(types: [Str(), `IntType`(), BoolType()]),
              Dict(types: [Str(), `IntType`(), BoolType()]),
            ]),
          PositionalArgument(
            name: "msg", varargs: true, opt: true,
            types: [
              Str(), `IntType`(), BoolType(), ListType(types: [Str(), `IntType`(), BoolType()]),
              Dict(types: [Str(), `IntType`(), BoolType()]),
            ]),
        ]),
      Function(
        name: "project",
        args: [
          PositionalArgument(name: "project_name", types: [Str()]),
          PositionalArgument(name: "language", varargs: true, opt: true, types: [Str()]),
          Kwarg(name: "default_options", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "license", opt: true, types: [ListType(types: [Str()]), Str()]),
          Kwarg(name: "meson_version", opt: true, types: [Str()]),
          Kwarg(name: "subproject_dir", opt: true, types: [Str()]),
          Kwarg(name: "version", opt: true, types: [Str(), File()]),
        ]),
      Function(
        name: "range", returnTypes: [RangeType()],
        args: [
          PositionalArgument(name: "start", opt: true, types: [`IntType`()]),
          PositionalArgument(name: "stop", opt: true, types: [`IntType`()]),
          PositionalArgument(name: "step", opt: true, types: [`IntType`()]),
        ]),
      Function(
        name: "run_command", returnTypes: [RunResult()],
        args: [
          PositionalArgument(
            name: "command", varargs: true, opt: true, types: [Str(), File(), ExternalProgram()]),
          Kwarg(name: "capture", opt: true, types: [BoolType()]),
          Kwarg(name: "check", opt: true, types: [BoolType()]),
          Kwarg(
            name: "env", opt: true, types: [Env(), ListType(types: [Str()]), Dict(types: [Str()])]),
        ]),
      Function(
        name: "run_target", returnTypes: [RunTgt()],
        args: [
          PositionalArgument(name: "target_name", types: [Str()]),
          Kwarg(
            name: "command",
            types: [ListType(types: [Exe(), ExternalProgram(), CustomTgt(), File(), Str()])]),
          Kwarg(name: "depends", opt: true, types: [ListType(types: [CustomTgt(), BuildTgt()])]),
          Kwarg(
            name: "env", opt: true, types: [Env(), ListType(types: [Str()]), Dict(types: [Str()])]),
        ]),
      Function(
        name: "set_variable",
        args: [
          PositionalArgument(name: "variable_name", types: [Str()]),
          PositionalArgument(name: "value", types: [`Any`()]),
        ]),
      Function(
        name: "shared_library", returnTypes: [Lib()],
        args: [
          PositionalArgument(name: "target_name", types: [Str()]),
          PositionalArgument(
            name: "source", varargs: true, opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]),
          Kwarg(name: "c_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cpp_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cs_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "d_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "fortran_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "java_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "objc_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "objcpp_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "rust_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "vala_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cython_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "nasm_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "masm_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "c_pch", opt: true, types: [Str()]),
          Kwarg(name: "cpp_pch", opt: true, types: [Str()]),
          Kwarg(name: "build_by_default", opt: true, types: [BoolType()]),
          Kwarg(name: "build_rpath", opt: true, types: [Str()]),
          Kwarg(name: "d_debug", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "d_import_dirs", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(
            name: "d_module_versions", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "d_unittest", opt: true, types: [BoolType()]),
          Kwarg(
            name: "darwin_versions", opt: true,
            types: [Str(), `IntType`(), ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()])]),
          Kwarg(name: "extra_files", opt: true, types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "gnu_symbol_visibility", opt: true, types: [Str()]),
          Kwarg(name: "gui_app", opt: true, types: [BoolType()]),
          Kwarg(name: "implicit_include_directories", opt: true, types: [BoolType()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Str(), Inc()])]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "install_rpath", opt: true, types: [Str()]),
          Kwarg(name: "install_tag", opt: true, types: [Str()]),
          Kwarg(name: "link_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "link_depends", opt: true, types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "link_language", opt: true, types: [Str()]),
          Kwarg(
            name: "link_whole", opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]),
          Kwarg(
            name: "link_with", opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]),
          Kwarg(name: "name_prefix", opt: true, types: [Str(), ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [Str(), ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: [BoolType()]),
          Kwarg(
            name: "objects", opt: true, types: [ListType(types: [ExtractedObj(), File(), Str()])]),
          Kwarg(name: "override_options", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "rust_crate_type", opt: true, types: [Str()]),
          Kwarg(
            name: "sources", opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList(), StructuredSrc()]),
          Kwarg(name: "soversion", opt: true, types: [Str(), `IntType`()]),
          Kwarg(name: "version", opt: true, types: [Str()]),
          Kwarg(
            name: "vs_module_defs", opt: true, types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "win_subsystem", opt: true, types: [Str()]),
        ]),
      Function(
        name: "shared_module", returnTypes: [BuildTgt()],
        args: [
          PositionalArgument(name: "target_name", types: [Str()]),
          PositionalArgument(
            name: "source", varargs: true, opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]),
          Kwarg(name: "c_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cpp_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cs_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "d_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "fortran_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "java_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "objc_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "objcpp_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "rust_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "vala_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cython_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "nasm_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "masm_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "c_pch", opt: true, types: [Str()]),
          Kwarg(name: "cpp_pch", opt: true, types: [Str()]),
          Kwarg(name: "build_by_default", opt: true, types: [BoolType()]),
          Kwarg(name: "build_rpath", opt: true, types: [Str()]),
          Kwarg(name: "d_debug", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "d_import_dirs", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(
            name: "d_module_versions", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "d_unittest", opt: true, types: [BoolType()]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()])]),
          Kwarg(name: "extra_files", opt: true, types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "gnu_symbol_visibility", opt: true, types: [Str()]),
          Kwarg(name: "gui_app", opt: true, types: [BoolType()]),
          Kwarg(name: "implicit_include_directories", opt: true, types: [BoolType()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Str(), Inc()])]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "install_rpath", opt: true, types: [Str()]),
          Kwarg(name: "install_tag", opt: true, types: [Str()]),
          Kwarg(name: "link_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "link_depends", opt: true, types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "link_language", opt: true, types: [Str()]),
          Kwarg(
            name: "link_whole", opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]),
          Kwarg(
            name: "link_with", opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]),
          Kwarg(name: "name_prefix", opt: true, types: [Str(), ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [Str(), ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: [BoolType()]),
          Kwarg(
            name: "objects", opt: true, types: [ListType(types: [ExtractedObj(), File(), Str()])]),
          Kwarg(name: "override_options", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "rust_crate_type", opt: true, types: [Str()]),
          Kwarg(
            name: "sources", opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList(), StructuredSrc()]),
          Kwarg(
            name: "vs_module_defs", opt: true, types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "win_subsystem", opt: true, types: [Str()]),
        ]),
      Function(
        name: "static_library", returnTypes: [Lib()],
        args: [
          PositionalArgument(name: "target_name", types: [Str()]),
          PositionalArgument(
            name: "source", varargs: true, opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]),
          Kwarg(name: "c_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cpp_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cs_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "d_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "fortran_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "java_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "objc_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "objcpp_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "rust_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "vala_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "cython_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "nasm_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "masm_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "c_pch", opt: true, types: [Str()]),
          Kwarg(name: "cpp_pch", opt: true, types: [Str()]),
          Kwarg(name: "build_by_default", opt: true, types: [BoolType()]),
          Kwarg(name: "build_rpath", opt: true, types: [Str()]),
          Kwarg(name: "d_debug", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "d_import_dirs", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(
            name: "d_module_versions", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "d_unittest", opt: true, types: [BoolType()]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()])]),
          Kwarg(name: "extra_files", opt: true, types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "gnu_symbol_visibility", opt: true, types: [Str()]),
          Kwarg(name: "gui_app", opt: true, types: [BoolType()]),
          Kwarg(name: "implicit_include_directories", opt: true, types: [BoolType()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Str(), Inc()])]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "install_rpath", opt: true, types: [Str()]),
          Kwarg(name: "install_tag", opt: true, types: [Str()]),
          Kwarg(name: "link_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "link_depends", opt: true, types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "link_language", opt: true, types: [Str()]),
          Kwarg(
            name: "link_whole", opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]),
          Kwarg(
            name: "link_with", opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]),
          Kwarg(name: "name_prefix", opt: true, types: [Str(), ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [Str(), ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: [BoolType()]),
          Kwarg(
            name: "objects", opt: true, types: [ListType(types: [ExtractedObj(), File(), Str()])]),
          Kwarg(name: "override_options", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "pic", opt: true, types: [BoolType()]),
          Kwarg(name: "prelink", opt: true, types: [BoolType()]),
          Kwarg(name: "rust_crate_type", opt: true, types: [Str()]),
          Kwarg(
            name: "sources", opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList(), StructuredSrc()]),
          Kwarg(name: "soversion", opt: true, types: [Str(), `IntType`()]),
          Kwarg(name: "version", opt: true, types: [Str()]),
          Kwarg(
            name: "vs_module_defs", opt: true, types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "win_subsystem", opt: true, types: [Str()]),
        ]),
      Function(
        name: "structured_sources", returnTypes: [StructuredSrc()],
        args: [
          PositionalArgument(
            name: "root",
            types: [ListType(types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()])]),
          PositionalArgument(
            name: "additional", opt: true,
            types: [Dict(types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()])]),
        ]),
      Function(
        name: "subdir",
        args: [
          PositionalArgument(name: "dir_name", types: [Str()]),
          Kwarg(name: "if_found", opt: true, types: [ListType(types: [Dep()])]),
        ]), Function(name: "subdir_done"),
      Function(
        name: "subproject", returnTypes: [Subproject()],
        args: [
          PositionalArgument(name: "subproject_name", types: [Str()]),
          Kwarg(name: "default_options", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "required", opt: true, types: [BoolType(), Feature()]),
          Kwarg(name: "version", opt: true, types: [Str()]),
        ]),
      Function(
        name: "summary",
        args: [
          PositionalArgument(
            name: "key_or_dict",
            types: [
              Str(),
              Dict(types: [
                Str(), BoolType(), `IntType`(), Dep(), ExternalProgram(),
                ListType(types: [Str(), BoolType(), `IntType`(), Dep(), ExternalProgram()]),
              ]),
            ]),
          PositionalArgument(
            name: "value", opt: true,
            types: [
              Str(), BoolType(), `IntType`(), Dep(), ExternalProgram(),
              ListType(types: [Str(), BoolType(), `IntType`(), Dep(), ExternalProgram()]),
            ]), Kwarg(name: "bool_yn", opt: true, types: [BoolType()]),
          Kwarg(name: "list_sep", opt: true, types: [Str()]),
          Kwarg(name: "section", opt: true, types: [Str()]),
        ]),
      Function(
        name: "test",
        args: [
          PositionalArgument(name: "name", types: [Str()]),
          PositionalArgument(name: "executable", types: [Exe(), Jar(), ExternalProgram(), File()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str(), File(), Tgt()])]),
          Kwarg(name: "depends", opt: true, types: [ListType(types: [BuildTgt(), CustomTgt()])]),
          Kwarg(
            name: "env", opt: true, types: [Str(), ListType(types: [Str()]), Dict(types: [Str()])]),
          Kwarg(name: "is_parallel", opt: true, types: [BoolType()]),
          Kwarg(name: "priority", opt: true, types: [`IntType`()]),
          Kwarg(name: "protocol", opt: true, types: [Str()]),
          Kwarg(name: "should_fail", opt: true, types: [BoolType()]),
          Kwarg(name: "suite", opt: true, types: [Str(), ListType(types: [Str()])]),
          Kwarg(name: "timeout", opt: true, types: [`IntType`()]),
          Kwarg(name: "verbose", opt: true, types: [BoolType()]),
          Kwarg(name: "workdir", opt: true, types: [Str()]),
        ]),
      Function(name: "unset_variable", args: [PositionalArgument(name: "varname", types: [Str()])]),
      Function(
        name: "vcs_tag", returnTypes: [CustomTgt()],
        args: [
          Kwarg(
            name: "command", opt: true,
            types: [ListType(types: [Exe(), ExternalProgram(), CustomTgt(), File(), Str()])]),
          Kwarg(name: "fallback", opt: true, types: [Str()]), Kwarg(name: "input", types: [Str()]),
          Kwarg(name: "output", types: [Str()]),
          Kwarg(name: "replace_string", opt: true, types: [Str()]),
        ]),
      Function(
        name: "warning",
        args: [
          PositionalArgument(
            name: "message",
            types: [
              Str(), `IntType`(), BoolType(), ListType(types: [Str(), `IntType`(), BoolType()]),
              Dict(types: [Str(), `IntType`(), BoolType()]),
            ]),
          PositionalArgument(
            name: "msg", varargs: true, opt: true,
            types: [
              Str(), `IntType`(), BoolType(), ListType(types: [Str(), `IntType`(), BoolType()]),
              Dict(types: [Str(), `IntType`(), BoolType()]),
            ]),
        ]),
    ]
  }

  public func lookupFunction(name: String) -> Function? {
    for f in self.functions where f.name == name { return f }
    return nil
  }
}
