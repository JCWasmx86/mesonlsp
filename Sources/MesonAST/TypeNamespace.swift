public class TypeNamespace {
  public var functions: [Function] = []
  public var types: [String: Type]
  public var vtables: [String: [Method]]

  public init() {
    types = [
      "any": `Any`(), "bool": BoolType(), "build_machine": BuildMachine(), "dict": Dict(types: []),
      "host_machine": HostMachine(), "int": IntType(), "list": ListType(types: []),
      "meson": Meson(), "str": Str(), "target_machine": TargetMachine(), "alias_tgt": AliasTgt(),
      "both_libs": BothLibs(), "build_tgt": BuildTgt(), "cfg_data": CfgData(),
      "compiler": Compiler(), "custom_idx": CustomIdx(), "custom_tgt": CustomTgt(), "dep": Dep(),
      "disabler": Disabler(), "env": Env(), "exe": Exe(), "external_program": ExternalProgram(),
      "extracted_obj": ExtractedObj(), "feature": Feature(), "file": File(),
      "generated_list": GeneratedList(), "generator": Generator(), "inc": Inc(), "jar": Jar(),
      "lib": Lib(), "module": Module(), "range": RangeType(), "runresult": RunResult(),
      "run_tgt": RunTgt(), "structured_src": StructuredSrc(), "subproject": Subproject(),
      "tgt": Tgt(), "cmake_module": CMakeModule(), "cmake_subproject": CMakeSubproject(),
      "cmake_subprojectoptions": CMakeSubprojectOptions(), "cmake_tgt": CMakeTarget(),
      "fs_module": FSModule(), "i18n_module": I18nModule(), "gnome_module": GNOMEModule(),
      "rust_module": RustModule(), "python_module": PythonModule(),
      "python_installation": PythonInstallation(), "python3_module": Python3Module(),
      "pkgconfig_module": PkgconfigModule(), "keyval_module": KeyvalModule(),
      "dlang_module": DlangModule(), "external_project_module": ExternalProjectModule(),
      "external_project": ExternalProject(), "hotdoc_module": HotdocModule(),
      "hotdoc_target": HotdocTarget(), "java_module": JavaModule(),
      "windows_module": WindowsModule(), "cuda_module": CudaModule(),
      "icestorm_module": IcestormModule(), "qt4_module": Qt4Module(), "qt5_module": Qt5Module(),
      "qt6_module": Qt6Module(), "wayland_module": WaylandModule(), "simd_module": SIMDModule(),
      "sourceset_module": SourcesetModule(), "sourceset": SourceSet(), "sourcefiles": SourceFiles(),
    ]
    let str = self.types["str"]!
    let strlist = ListType(types: [str])
    let strlistL = [strlist]
    let strL = [str]
    let boolt = self.types["bool"]!
    let boolL = [boolt]
    let intt = self.types["int"]!
    let inttL = [intt]
    let sil = [str, intt]
    let silb = [str, intt, boolt]
    self.functions = [
      Function(
        name: "add_global_arguments",
        args: [
          PositionalArgument(name: "arg", varargs: true, opt: true, types: strL),
          Kwarg(name: "language", types: strlistL), Kwarg(name: "native", opt: true, types: boolL),
        ]
      ),
      Function(
        name: "add_global_link_arguments",
        args: [
          PositionalArgument(name: "arg", varargs: true, opt: true, types: strL),
          Kwarg(name: "language", types: strlistL), Kwarg(name: "native", opt: true, types: boolL),
        ]
      ),
      Function(
        name: "add_languages",
        returnTypes: boolL,
        args: [
          PositionalArgument(name: "language", varargs: true, opt: true, types: strL),
          Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(name: "required", opt: true, types: boolL),
        ]
      ),
      Function(
        name: "add_project_arguments",
        args: [
          PositionalArgument(name: "arg", varargs: true, opt: true, types: strL),
          Kwarg(name: "language", types: strlistL), Kwarg(name: "native", opt: true, types: boolL),
        ]
      ),
      Function(
        name: "add_project_dependencies",
        args: [
          PositionalArgument(name: "dependency", varargs: true, opt: true, types: [Dep()]),
          Kwarg(name: "language", types: strlistL), Kwarg(name: "native", opt: true, types: boolL),
        ]
      ),
      Function(
        name: "add_project_link_arguments",
        args: [
          PositionalArgument(name: "arg", varargs: true, opt: true, types: strL),
          Kwarg(name: "language", types: strlistL), Kwarg(name: "native", opt: true, types: boolL),
        ]
      ),
      Function(
        name: "add_test_setup",
        args: [
          PositionalArgument(name: "name", types: strL),
          Kwarg(name: "env", opt: true, types: [Env(), ListType(types: strL), Dict(types: strL)]),
          Kwarg(name: "exclude_suites", opt: true, types: strlistL),
          Kwarg(
            name: "exe_wrapper",
            opt: true,
            types: [ListType(types: [str, ExternalProgram()])]
          ), Kwarg(name: "gdb", opt: true, types: boolL),
          Kwarg(name: "is_default", opt: true, types: boolL),
          Kwarg(name: "timeout_multiplier", opt: true, types: inttL),
        ]
      ),
      Function(
        name: "alias_target",
        returnTypes: [AliasTgt()],
        args: [
          PositionalArgument(name: "target_name", types: strL),
          PositionalArgument(name: "dep", varargs: true, opt: false, types: [Dep()]),
        ]
      ),
      Function(
        name: "assert",
        args: [
          PositionalArgument(name: "condition", types: boolL),
          PositionalArgument(name: "message", opt: true, types: strL),
        ]
      ),
      Function(
        name: "benchmark",
        args: [
          PositionalArgument(name: "name", types: strL),
          PositionalArgument(name: "executable", types: [Exe(), Jar(), ExternalProgram(), File()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [str, File(), Tgt()])]),
          Kwarg(name: "depends", opt: true, types: [ListType(types: [BuildTgt(), CustomTgt()])]),
          Kwarg(name: "env", opt: true, types: [str, ListType(types: strL), Dict(types: strL)]),
          Kwarg(name: "priority", opt: true, types: inttL),
          Kwarg(name: "protocol", opt: true, types: strL),
          Kwarg(name: "should_fail", opt: true, types: boolL),
          Kwarg(name: "suite", opt: true, types: [str, ListType(types: strL)]),
          Kwarg(name: "timeout", opt: true, types: inttL),
          Kwarg(name: "verbose", opt: true, types: boolL),
          Kwarg(name: "workdir", opt: true, types: strL),
        ]
      ),
      Function(
        name: "both_libraries",
        returnTypes: [BothLibs()],
        args: [
          PositionalArgument(name: "target_name", types: strL),
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: true,
            types: [str, File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "c_args", opt: true, types: strlistL),
          Kwarg(name: "cpp_args", opt: true, types: strlistL),
          Kwarg(name: "cs_args", opt: true, types: strlistL),
          Kwarg(name: "cuda_args", opt: true, types: strlistL),
          Kwarg(name: "d_args", opt: true, types: strlistL),
          Kwarg(name: "fortran_args", opt: true, types: strlistL),
          Kwarg(name: "java_args", opt: true, types: strlistL),
          Kwarg(name: "objc_args", opt: true, types: strlistL),
          Kwarg(name: "objcpp_args", opt: true, types: strlistL),
          Kwarg(name: "rust_args", opt: true, types: strlistL),
          Kwarg(name: "vala_args", opt: true, types: strlistL),
          Kwarg(name: "cython_args", opt: true, types: strlistL),
          Kwarg(name: "nasm_args", opt: true, types: strlistL),
          Kwarg(name: "masm_args", opt: true, types: strlistL),
          Kwarg(name: "c_pch", opt: true, types: strL),
          Kwarg(name: "cpp_pch", opt: true, types: strL),
          Kwarg(name: "resources", opt: true, types: strL),
          Kwarg(name: "vala_header", opt: true, types: strL),
          Kwarg(name: "vala_vapi", opt: true, types: strL),
          Kwarg(name: "vala_gir", opt: true, types: strL),
          Kwarg(name: "build_by_default", opt: true, types: boolL),
          Kwarg(name: "build_rpath", opt: true, types: strL),
          Kwarg(name: "d_debug", opt: true, types: strlistL),
          Kwarg(name: "d_import_dirs", opt: true, types: strlistL),
          Kwarg(name: "d_module_versions", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "d_unittest", opt: true, types: boolL),
          Kwarg(name: "darwin_versions", opt: true, types: [str, intt, ListType(types: strL)]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()])]),
          Kwarg(name: "extra_files", opt: true, types: [str, File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "gnu_symbol_visibility", opt: true, types: strL),
          Kwarg(name: "gui_app", opt: true, types: boolL),
          Kwarg(name: "implicit_include_directories", opt: true, types: boolL),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [str, Inc()])]),
          Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "install_rpath", opt: true, types: strL),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "link_args", opt: true, types: strlistL),
          Kwarg(name: "link_depends", opt: true, types: [str, File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "link_language", opt: true, types: strL),
          Kwarg(
            name: "link_whole",
            opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]
          ),
          Kwarg(
            name: "link_with",
            opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]
          ), Kwarg(name: "name_prefix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(
            name: "objects",
            opt: true,
            types: [ListType(types: [ExtractedObj(), File(), str])]
          ), Kwarg(name: "override_options", opt: true, types: strlistL),
          Kwarg(name: "pic", opt: true, types: boolL),
          Kwarg(name: "prelink", opt: true, types: boolL),
          Kwarg(name: "rust_crate_type", opt: true, types: strL),
          Kwarg(
            name: "sources",
            opt: true,
            types: [str, File(), CustomTgt(), CustomIdx(), GeneratedList(), StructuredSrc()]
          ), Kwarg(name: "soversion", opt: true, types: sil),
          Kwarg(name: "version", opt: true, types: strL),
          Kwarg(name: "vs_module_defs", opt: true, types: [str, File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "win_subsystem", opt: true, types: strL),
        ]
      ),
      Function(
        name: "build_target",
        returnTypes: [BuildTgt()],
        args: [
          PositionalArgument(name: "target_name", types: strL),
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: true,
            types: [str, File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "c_args", opt: true, types: strlistL),
          Kwarg(name: "cpp_args", opt: true, types: strlistL),
          Kwarg(name: "cs_args", opt: true, types: strlistL),
          Kwarg(name: "cuda_args", opt: true, types: strlistL),
          Kwarg(name: "d_args", opt: true, types: strlistL),
          Kwarg(name: "fortran_args", opt: true, types: strlistL),
          Kwarg(name: "java_args", opt: true, types: strlistL),
          Kwarg(name: "objc_args", opt: true, types: strlistL),
          Kwarg(name: "objcpp_args", opt: true, types: strlistL),
          Kwarg(name: "rust_args", opt: true, types: strlistL),
          Kwarg(name: "vala_args", opt: true, types: strlistL),
          Kwarg(name: "cython_args", opt: true, types: strlistL),
          Kwarg(name: "nasm_args", opt: true, types: strlistL),
          Kwarg(name: "masm_args", opt: true, types: strlistL),
          Kwarg(name: "c_pch", opt: true, types: strL),
          Kwarg(name: "cpp_pch", opt: true, types: strL),
          Kwarg(name: "resources", opt: true, types: strL),
          Kwarg(name: "vala_header", opt: true, types: strL),
          Kwarg(name: "vala_vapi", opt: true, types: strL),
          Kwarg(name: "vala_gir", opt: true, types: strL),
          Kwarg(name: "build_by_default", opt: true, types: boolL),
          Kwarg(name: "build_rpath", opt: true, types: strL),
          Kwarg(name: "d_debug", opt: true, types: strlistL),
          Kwarg(name: "d_import_dirs", opt: true, types: strlistL),
          Kwarg(name: "d_module_versions", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "d_unittest", opt: true, types: boolL),
          Kwarg(name: "darwin_versions", opt: true, types: [str, intt, ListType(types: strL)]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()])]),
          Kwarg(name: "extra_files", opt: true, types: [str, File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "gnu_symbol_visibility", opt: true, types: strL),
          Kwarg(name: "gui_app", opt: true, types: boolL),
          Kwarg(name: "implib", opt: true, types: [boolt, str]),
          Kwarg(name: "implicit_include_directories", opt: true, types: boolL),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [str, Inc()])]),
          Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "install_rpath", opt: true, types: strL),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "java_resources", opt: true, types: [StructuredSrc()]),
          Kwarg(name: "link_args", opt: true, types: strlistL),
          Kwarg(name: "link_depends", opt: true, types: [str, File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "link_language", opt: true, types: strL),
          Kwarg(
            name: "link_whole",
            opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]
          ),
          Kwarg(
            name: "link_with",
            opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]
          ), Kwarg(name: "main_class", opt: true, types: strL),
          Kwarg(name: "name_prefix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(
            name: "objects",
            opt: true,
            types: [ListType(types: [ExtractedObj(), File(), str])]
          ), Kwarg(name: "override_options", opt: true, types: strlistL),
          Kwarg(name: "pic", opt: true, types: boolL), Kwarg(name: "pie", opt: true, types: boolL),
          Kwarg(name: "prelink", opt: true, types: boolL),
          Kwarg(name: "rust_crate_type", opt: true, types: strL),
          Kwarg(
            name: "sources",
            opt: true,
            types: [str, File(), CustomTgt(), CustomIdx(), GeneratedList(), StructuredSrc()]
          ), Kwarg(name: "soversion", opt: true, types: sil),
          Kwarg(name: "version", opt: true, types: strL), Kwarg(name: "target_type", types: strL),
          Kwarg(name: "vs_module_defs", opt: true, types: [str, File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "win_subsystem", opt: true, types: strL),
        ]
      ),
      Function(
        name: "configuration_data",
        returnTypes: [CfgData()],
        args: [
          PositionalArgument(name: "data", opt: true, types: [Dict(types: [str, boolt, intt])])
        ]
      ),
      Function(
        name: "configure_file",
        returnTypes: [File()],
        args: [
          Kwarg(name: "capture", opt: true, types: boolL),
          Kwarg(name: "command", opt: true, types: [ListType(types: [str, File()])]),
          Kwarg(name: "configuration", opt: true, types: [Dict(types: silb), CfgData()]),
          Kwarg(name: "copy", opt: true, types: boolL),
          Kwarg(name: "depfile", opt: true, types: strL),
          Kwarg(name: "encoding", opt: true, types: strL),
          Kwarg(name: "format", opt: true, types: strL),
          Kwarg(name: "input", opt: true, types: [str, File()]),
          Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "install_tag", opt: true, types: strL), Kwarg(name: "output", types: strL),
          Kwarg(name: "output_format", opt: true, types: strL),
        ]
      ),
      Function(
        name: "custom_target",
        returnTypes: [CustomTgt()],
        args: [
          PositionalArgument(name: "name", opt: true, types: strL),
          Kwarg(name: "build_always", opt: true, types: boolL),
          Kwarg(name: "build_always_stale", opt: true, types: boolL),
          Kwarg(name: "build_by_default", opt: true, types: boolL),
          Kwarg(name: "capture", opt: true, types: boolL),
          Kwarg(
            name: "command",
            types: [ListType(types: [str, File(), Exe(), ExternalProgram()])]
          ), Kwarg(name: "console", opt: true, types: boolL),
          Kwarg(name: "depend_files", opt: true, types: [ListType(types: [str, File()])]),
          Kwarg(name: "depends", opt: true, types: [ListType(types: [BuildTgt(), CustomTgt()])]),
          Kwarg(name: "depfile", opt: true, types: strL),
          Kwarg(name: "env", opt: true, types: [Env(), ListType(types: strL), Dict(types: strL)]),
          Kwarg(name: "feed", opt: true, types: boolL),
          Kwarg(name: "input", opt: true, types: [ListType(types: [str, File()])]),
          Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "output", types: strlistL),
        ]
      ),
      Function(
        name: "debug",
        args: [
          PositionalArgument(
            name: "message",
            types: [str, intt, boolt, ListType(types: silb), Dict(types: silb)]
          ),
          PositionalArgument(
            name: "msg",
            varargs: true,
            opt: true,
            types: [str, intt, boolt, ListType(types: silb), Dict(types: silb)]
          ),
        ]
      ),
      Function(
        name: "declare_dependency",
        returnTypes: [Dep()],
        args: [
          Kwarg(name: "compile_args", opt: true, types: strlistL),
          Kwarg(name: "d_import_dirs", opt: true, types: [ListType(types: [str, Inc()])]),
          Kwarg(name: "d_module_versions", opt: true, types: [str, intt, ListType(types: sil)]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()])]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [str, Inc()])]),
          Kwarg(name: "link_args", opt: true, types: strlistL),
          Kwarg(name: "link_whole", opt: true, types: [ListType(types: [Lib()])]),
          Kwarg(name: "link_with", opt: true, types: [ListType(types: [Lib()])]),
          Kwarg(name: "objects", opt: true, types: [ListType(types: [ExtractedObj()])]),
          Kwarg(
            name: "sources",
            opt: true,
            types: [ListType(types: [str, File(), CustomTgt(), CustomIdx(), GeneratedList()])]
          ),
          Kwarg(name: "variables", opt: true, types: [ListType(types: strL), Dict(types: strL)]),
          Kwarg(name: "version", opt: true, types: strL),
        ]
      ),
      Function(
        name: "dependency",
        returnTypes: [Dep()],
        args: [
          PositionalArgument(name: "names", varargs: true, types: strL),
          Kwarg(name: "allow_fallback", opt: true, types: boolL),
          Kwarg(name: "default_options", opt: true, types: strlistL),
          Kwarg(name: "components", opt: true, types: strlistL),
          Kwarg(name: "main", opt: true, types: boolL),
          Kwarg(name: "private_headers", opt: true, types: boolL),
          Kwarg(name: "disabler", opt: true, types: boolL),
          Kwarg(name: "fallback", opt: true, types: [str, ListType(types: strL)]),
          Kwarg(name: "cmake_module_path", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "include_type", opt: true, types: strL),
          Kwarg(name: "language", opt: true, types: strL),
          Kwarg(name: "method", opt: true, types: strL),
          Kwarg(name: "modules", opt: true, types: [str, ListType(types: strL)]),
          Kwarg(name: "optional_modules", opt: true, types: [str, ListType(types: strL)]),
          Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(name: "not_found_message", opt: true, types: strL),
          Kwarg(name: "required", opt: true, types: [boolt, Feature()]),
          Kwarg(name: "static", opt: true, types: boolL),
          Kwarg(name: "version", opt: true, types: strL),
          Kwarg(name: "cmake_package_version", opt: true, types: strL),
        ]
      ), Function(name: "disabler", returnTypes: [Disabler()]),
      Function(
        name: "environment",
        returnTypes: [Env()],
        args: [
          PositionalArgument(
            name: "env",
            opt: true,
            types: [str, ListType(types: strL), Dict(types: strL), Dict(types: strlistL)]
          ), Kwarg(name: "method", opt: true, types: strL),
          Kwarg(name: "separator", opt: true, types: strL),
        ]
      ),
      Function(
        name: "error",
        args: [
          PositionalArgument(name: "message", types: strL),
          PositionalArgument(name: "msg", varargs: true, opt: true, types: strL),
        ]
      ),
      Function(
        name: "executable",
        returnTypes: [Exe()],
        args: [
          PositionalArgument(name: "target_name", types: strL),
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: true,
            types: [str, File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "c_args", opt: true, types: strlistL),
          Kwarg(name: "cpp_args", opt: true, types: strlistL),
          Kwarg(name: "cs_args", opt: true, types: strlistL),
          Kwarg(name: "cuda_args", opt: true, types: strlistL),
          Kwarg(name: "d_args", opt: true, types: strlistL),
          Kwarg(name: "fortran_args", opt: true, types: strlistL),
          Kwarg(name: "java_args", opt: true, types: strlistL),
          Kwarg(name: "objc_args", opt: true, types: strlistL),
          Kwarg(name: "objcpp_args", opt: true, types: strlistL),
          Kwarg(name: "rust_args", opt: true, types: strlistL),
          Kwarg(name: "vala_args", opt: true, types: strlistL),
          Kwarg(name: "cython_args", opt: true, types: strlistL),
          Kwarg(name: "nasm_args", opt: true, types: strlistL),
          Kwarg(name: "masm_args", opt: true, types: strlistL),
          Kwarg(name: "c_pch", opt: true, types: strL),
          Kwarg(name: "cpp_pch", opt: true, types: strL),
          Kwarg(name: "resources", opt: true, types: strL),
          Kwarg(name: "vala_header", opt: true, types: strL),
          Kwarg(name: "vala_vapi", opt: true, types: strL),
          Kwarg(name: "vala_gir", opt: true, types: strL),
          Kwarg(name: "build_by_default", opt: true, types: boolL),
          Kwarg(name: "build_rpath", opt: true, types: strL),
          Kwarg(name: "d_debug", opt: true, types: strlistL),
          Kwarg(name: "d_import_dirs", opt: true, types: strlistL),
          Kwarg(name: "d_module_versions", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "d_unittest", opt: true, types: boolL),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()])]),
          Kwarg(name: "export_dynamic", opt: true, types: boolL),
          Kwarg(name: "extra_files", opt: true, types: [str, File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "gnu_symbol_visibility", opt: true, types: strL),
          Kwarg(name: "gui_app", opt: true, types: boolL),
          Kwarg(name: "implib", opt: true, types: [boolt, str]),
          Kwarg(name: "implicit_include_directories", opt: true, types: boolL),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [str, Inc()])]),
          Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "install_rpath", opt: true, types: strL),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "link_args", opt: true, types: strlistL),
          Kwarg(name: "link_depends", opt: true, types: [str, File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "link_language", opt: true, types: strL),
          Kwarg(
            name: "link_whole",
            opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]
          ),
          Kwarg(
            name: "link_with",
            opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]
          ), Kwarg(name: "name_prefix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(
            name: "objects",
            opt: true,
            types: [ListType(types: [ExtractedObj(), File(), str])]
          ), Kwarg(name: "override_options", opt: true, types: strlistL),
          Kwarg(name: "pie", opt: true, types: boolL),
          Kwarg(name: "rust_crate_type", opt: true, types: strL),
          Kwarg(
            name: "sources",
            opt: true,
            types: [str, File(), CustomTgt(), CustomIdx(), GeneratedList(), StructuredSrc()]
          ), Kwarg(name: "win_subsystem", opt: true, types: strL),
        ]
      ),
      Function(
        name: "files",
        returnTypes: [ListType(types: [File()])],
        args: [PositionalArgument(name: "file", varargs: true, opt: true, types: strL)]
      ),
      Function(
        name: "find_program",
        returnTypes: [ExternalProgram()],
        args: [
          PositionalArgument(name: "program_name", types: [str, File()]),
          PositionalArgument(name: "fallback", varargs: true, opt: true, types: [str, File()]),
          Kwarg(name: "dirs", opt: true, types: strlistL),
          Kwarg(name: "disabler", opt: true, types: boolL),
          Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(name: "required", opt: true, types: [boolt, Feature()]),
          Kwarg(name: "version", opt: true, types: strL),
        ]
      ),
      Function(
        name: "generator",
        returnTypes: [Generator()],
        args: [
          PositionalArgument(name: "exe", types: [Exe(), ExternalProgram()]),
          Kwarg(name: "arguments", opt: true, types: strlistL),
          Kwarg(name: "capture", opt: true, types: boolL),
          Kwarg(name: "depends", opt: true, types: [ListType(types: [BuildTgt(), CustomTgt()])]),
          Kwarg(name: "depfile", opt: true, types: strL),
          Kwarg(name: "output", opt: true, types: strlistL),
        ]
      ),
      Function(
        name: "get_option",
        returnTypes: [str, intt, boolt, Feature(), ListType(types: silb)],
        args: [PositionalArgument(name: "option_name", types: strL)]
      ),
      Function(
        name: "get_variable",
        returnTypes: [`Any`()],
        args: [
          PositionalArgument(name: "variable_name", types: strL),
          PositionalArgument(name: "default", opt: true, types: [`Any`()]),
        ]
      ),
      Function(
        name: "import",
        returnTypes: [Module()],
        args: [
          PositionalArgument(name: "module_name", types: strL),
          Kwarg(name: "module_name", opt: true, types: boolL),
          Kwarg(name: "required", opt: true, types: [boolt, Feature()]),
          Kwarg(name: "disabler", opt: true, types: boolL),
        ]
      ),
      Function(
        name: "include_directories",
        returnTypes: [Inc()],
        args: [
          PositionalArgument(name: "includes", varargs: true, opt: true, types: strL),
          Kwarg(name: "is_system", opt: true, types: boolL),
        ]
      ),
      Function(
        name: "install_data",
        args: [
          PositionalArgument(name: "file", varargs: true, opt: true, types: [str, File()]),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "preserve_path", opt: true, types: boolL),
          Kwarg(name: "rename", opt: true, types: strlistL),
          Kwarg(name: "sources", opt: true, types: [ListType(types: [File(), str])]),
        ]
      ),
      Function(
        name: "install_emptydir",
        args: [
          PositionalArgument(name: "dirpath", varargs: true, opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "install_tag", opt: true, types: strL),
        ]
      ),
      Function(
        name: "install_headers",
        args: [
          PositionalArgument(name: "file", varargs: true, opt: true, types: [str, File()]),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "preserve_path", opt: true, types: boolL),
          Kwarg(name: "subdir", opt: true, types: strL),
        ]
      ),
      Function(
        name: "install_man",
        args: [
          PositionalArgument(name: "file", varargs: true, opt: true, types: [str, File()]),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "locale", opt: true, types: strL),
        ]
      ),
      Function(
        name: "install_subdir",
        args: [
          PositionalArgument(name: "subdir_name", types: strL),
          Kwarg(name: "exclude_directories", opt: true, types: strlistL),
          Kwarg(name: "exclude_files", opt: true, types: strlistL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "strip_directory", opt: true, types: boolL),
        ]
      ),
      Function(
        name: "install_symlink",
        args: [
          PositionalArgument(name: "link_name", types: strL),
          Kwarg(name: "install_dir", types: strL),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "pointing_to", types: strL),
        ]
      ),
      Function(
        name: "is_disabler",
        returnTypes: boolL,
        args: [PositionalArgument(name: "var", types: [`Any`()])]
      ),
      Function(
        name: "is_variable",
        returnTypes: boolL,
        args: [PositionalArgument(name: "var", types: boolL)]
      ),
      Function(
        name: "jar",
        returnTypes: [Jar()],
        args: [
          PositionalArgument(name: "target_name", types: strL),
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: true,
            types: [str, File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "c_args", opt: true, types: strlistL),
          Kwarg(name: "cpp_args", opt: true, types: strlistL),
          Kwarg(name: "cs_args", opt: true, types: strlistL),
          Kwarg(name: "cuda_args", opt: true, types: strlistL),
          Kwarg(name: "d_args", opt: true, types: strlistL),
          Kwarg(name: "fortran_args", opt: true, types: strlistL),
          Kwarg(name: "java_args", opt: true, types: strlistL),
          Kwarg(name: "objc_args", opt: true, types: strlistL),
          Kwarg(name: "objcpp_args", opt: true, types: strlistL),
          Kwarg(name: "rust_args", opt: true, types: strlistL),
          Kwarg(name: "vala_args", opt: true, types: strlistL),
          Kwarg(name: "cython_args", opt: true, types: strlistL),
          Kwarg(name: "nasm_args", opt: true, types: strlistL),
          Kwarg(name: "masm_args", opt: true, types: strlistL),
          Kwarg(name: "c_pch", opt: true, types: strL),
          Kwarg(name: "cpp_pch", opt: true, types: strL),
          Kwarg(name: "resources", opt: true, types: strL),
          Kwarg(name: "build_by_default", opt: true, types: boolL),
          Kwarg(name: "build_rpath", opt: true, types: strL),
          Kwarg(name: "d_debug", opt: true, types: strlistL),
          Kwarg(name: "d_import_dirs", opt: true, types: strlistL),
          Kwarg(name: "d_module_versions", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "d_unittest", opt: true, types: boolL),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()])]),
          Kwarg(name: "extra_files", opt: true, types: [str, File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "gnu_symbol_visibility", opt: true, types: strL),
          Kwarg(name: "gui_app", opt: true, types: boolL),
          Kwarg(name: "implicit_include_directories", opt: true, types: boolL),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [str, Inc()])]),
          Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "install_rpath", opt: true, types: strL),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "java_resources", opt: true, types: [StructuredSrc()]),
          Kwarg(name: "link_args", opt: true, types: strlistL),
          Kwarg(name: "link_depends", opt: true, types: [str, File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "link_language", opt: true, types: strL),
          Kwarg(
            name: "link_whole",
            opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]
          ),
          Kwarg(
            name: "link_with",
            opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]
          ), Kwarg(name: "main_class", opt: true, types: strL),
          Kwarg(name: "name_prefix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(
            name: "objects",
            opt: true,
            types: [ListType(types: [ExtractedObj(), File(), str])]
          ), Kwarg(name: "override_options", opt: true, types: strlistL),
          Kwarg(name: "rust_crate_type", opt: true, types: strL),
          Kwarg(
            name: "sources",
            opt: true,
            types: [str, File(), CustomTgt(), CustomIdx(), GeneratedList(), StructuredSrc()]
          ), Kwarg(name: "win_subsystem", opt: true, types: strL),
        ]
      ),
      Function(
        name: "join_paths",
        returnTypes: strL,
        args: [PositionalArgument(name: "part", varargs: true, types: strL)]
      ),
      Function(
        name: "library",
        returnTypes: [Lib()],
        args: [
          PositionalArgument(name: "target_name", types: strL),
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: true,
            types: [str, File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "c_args", opt: true, types: strlistL),
          Kwarg(name: "cpp_args", opt: true, types: strlistL),
          Kwarg(name: "cs_args", opt: true, types: strlistL),
          Kwarg(name: "cuda_args", opt: true, types: strlistL),
          Kwarg(name: "d_args", opt: true, types: strlistL),
          Kwarg(name: "fortran_args", opt: true, types: strlistL),
          Kwarg(name: "java_args", opt: true, types: strlistL),
          Kwarg(name: "objc_args", opt: true, types: strlistL),
          Kwarg(name: "objcpp_args", opt: true, types: strlistL),
          Kwarg(name: "rust_args", opt: true, types: strlistL),
          Kwarg(name: "vala_args", opt: true, types: strlistL),
          Kwarg(name: "cython_args", opt: true, types: strlistL),
          Kwarg(name: "nasm_args", opt: true, types: strlistL),
          Kwarg(name: "masm_args", opt: true, types: strlistL),
          Kwarg(name: "c_pch", opt: true, types: strL),
          Kwarg(name: "cpp_pch", opt: true, types: strL),
          Kwarg(name: "resources", opt: true, types: strL),
          Kwarg(name: "vala_header", opt: true, types: strL),
          Kwarg(name: "vala_vapi", opt: true, types: strL),
          Kwarg(name: "vala_gir", opt: true, types: strL),
          Kwarg(name: "build_by_default", opt: true, types: boolL),
          Kwarg(name: "build_rpath", opt: true, types: strL),
          Kwarg(name: "d_debug", opt: true, types: strlistL),
          Kwarg(name: "d_import_dirs", opt: true, types: strlistL),
          Kwarg(name: "d_module_versions", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "d_unittest", opt: true, types: boolL),
          Kwarg(name: "darwin_versions", opt: true, types: [str, intt, ListType(types: strL)]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()])]),
          Kwarg(name: "extra_files", opt: true, types: [str, File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "gnu_symbol_visibility", opt: true, types: strL),
          Kwarg(name: "gui_app", opt: true, types: boolL),
          Kwarg(name: "implicit_include_directories", opt: true, types: boolL),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [str, Inc()])]),
          Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "install_rpath", opt: true, types: strL),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "link_args", opt: true, types: strlistL),
          Kwarg(name: "link_depends", opt: true, types: [str, File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "link_language", opt: true, types: strL),
          Kwarg(
            name: "link_whole",
            opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]
          ),
          Kwarg(
            name: "link_with",
            opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]
          ), Kwarg(name: "name_prefix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(
            name: "objects",
            opt: true,
            types: [ListType(types: [ExtractedObj(), File(), str])]
          ), Kwarg(name: "override_options", opt: true, types: strlistL),
          Kwarg(name: "pic", opt: true, types: boolL),
          Kwarg(name: "prelink", opt: true, types: boolL),
          Kwarg(name: "rust_crate_type", opt: true, types: strL),
          Kwarg(
            name: "sources",
            opt: true,
            types: [str, File(), CustomTgt(), CustomIdx(), GeneratedList(), StructuredSrc()]
          ), Kwarg(name: "soversion", opt: true, types: sil),
          Kwarg(name: "version", opt: true, types: strL),
          Kwarg(name: "vs_module_defs", opt: true, types: [str, File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "win_subsystem", opt: true, types: strL),
        ]
      ),
      Function(
        name: "message",
        args: [
          PositionalArgument(
            name: "message",
            types: [str, intt, boolt, ListType(types: silb), Dict(types: silb)]
          ),
          PositionalArgument(
            name: "msg",
            varargs: true,
            opt: true,
            types: [str, intt, boolt, ListType(types: silb), Dict(types: silb)]
          ),
        ]
      ),
      Function(
        name: "project",
        args: [
          PositionalArgument(name: "project_name", types: strL),
          PositionalArgument(name: "language", varargs: true, opt: true, types: strL),
          Kwarg(name: "default_options", opt: true, types: strlistL),
          Kwarg(name: "license_files", opt: true, types: [strlist, str]),
          Kwarg(name: "license", opt: true, types: [ListType(types: strL), str]),
          Kwarg(name: "meson_version", opt: true, types: strL),
          Kwarg(name: "subproject_dir", opt: true, types: strL),
          Kwarg(name: "version", opt: true, types: [str, File()]),
        ]
      ),
      Function(
        name: "range",
        returnTypes: [RangeType()],
        args: [
          PositionalArgument(name: "start", opt: true, types: inttL),
          PositionalArgument(name: "stop", opt: true, types: inttL),
          PositionalArgument(name: "step", opt: true, types: inttL),
        ]
      ),
      Function(
        name: "run_command",
        returnTypes: [RunResult()],
        args: [
          PositionalArgument(
            name: "command",
            varargs: true,
            opt: true,
            types: [str, File(), ExternalProgram()]
          ), Kwarg(name: "capture", opt: true, types: boolL),
          Kwarg(name: "check", opt: true, types: boolL),
          Kwarg(name: "env", opt: true, types: [Env(), ListType(types: strL), Dict(types: strL)]),
        ]
      ),
      Function(
        name: "run_target",
        returnTypes: [RunTgt()],
        args: [
          PositionalArgument(name: "target_name", types: strL),
          Kwarg(
            name: "command",
            types: [ListType(types: [Exe(), ExternalProgram(), CustomTgt(), File(), str])]
          ),
          Kwarg(name: "depends", opt: true, types: [ListType(types: [CustomTgt(), BuildTgt()])]),
          Kwarg(name: "env", opt: true, types: [Env(), ListType(types: strL), Dict(types: strL)]),
        ]
      ),
      Function(
        name: "set_variable",
        args: [
          PositionalArgument(name: "variable_name", types: strL),
          PositionalArgument(name: "value", types: [`Any`()]),
        ]
      ),
      Function(
        name: "shared_library",
        returnTypes: [Lib()],
        args: [
          PositionalArgument(name: "target_name", types: strL),
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: true,
            types: [str, File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "c_args", opt: true, types: strlistL),
          Kwarg(name: "cpp_args", opt: true, types: strlistL),
          Kwarg(name: "cs_args", opt: true, types: strlistL),
          Kwarg(name: "cuda_args", opt: true, types: strlistL),
          Kwarg(name: "d_args", opt: true, types: strlistL),
          Kwarg(name: "fortran_args", opt: true, types: strlistL),
          Kwarg(name: "java_args", opt: true, types: strlistL),
          Kwarg(name: "objc_args", opt: true, types: strlistL),
          Kwarg(name: "objcpp_args", opt: true, types: strlistL),
          Kwarg(name: "rust_args", opt: true, types: strlistL),
          Kwarg(name: "vala_args", opt: true, types: strlistL),
          Kwarg(name: "cython_args", opt: true, types: strlistL),
          Kwarg(name: "nasm_args", opt: true, types: strlistL),
          Kwarg(name: "masm_args", opt: true, types: strlistL),
          Kwarg(name: "c_pch", opt: true, types: strL),
          Kwarg(name: "cpp_pch", opt: true, types: strL),
          Kwarg(name: "resources", opt: true, types: strL),
          Kwarg(name: "vala_header", opt: true, types: strL),
          Kwarg(name: "vala_vapi", opt: true, types: strL),
          Kwarg(name: "vala_gir", opt: true, types: strL),
          Kwarg(name: "build_by_default", opt: true, types: boolL),
          Kwarg(name: "build_rpath", opt: true, types: strL),
          Kwarg(name: "d_debug", opt: true, types: strlistL),
          Kwarg(name: "d_import_dirs", opt: true, types: strlistL),
          Kwarg(name: "d_module_versions", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "d_unittest", opt: true, types: boolL),
          Kwarg(name: "darwin_versions", opt: true, types: [str, intt, ListType(types: strL)]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()])]),
          Kwarg(name: "extra_files", opt: true, types: [str, File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "gnu_symbol_visibility", opt: true, types: strL),
          Kwarg(name: "gui_app", opt: true, types: boolL),
          Kwarg(name: "implicit_include_directories", opt: true, types: boolL),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [str, Inc()])]),
          Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "install_rpath", opt: true, types: strL),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "link_args", opt: true, types: strlistL),
          Kwarg(name: "link_depends", opt: true, types: [str, File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "link_language", opt: true, types: strL),
          Kwarg(
            name: "link_whole",
            opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]
          ),
          Kwarg(
            name: "link_with",
            opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]
          ), Kwarg(name: "name_prefix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(
            name: "objects",
            opt: true,
            types: [ListType(types: [ExtractedObj(), File(), str])]
          ), Kwarg(name: "override_options", opt: true, types: strlistL),
          Kwarg(name: "rust_crate_type", opt: true, types: strL),
          Kwarg(
            name: "sources",
            opt: true,
            types: [str, File(), CustomTgt(), CustomIdx(), GeneratedList(), StructuredSrc()]
          ), Kwarg(name: "soversion", opt: true, types: sil),
          Kwarg(name: "version", opt: true, types: strL),
          Kwarg(name: "vs_module_defs", opt: true, types: [str, File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "win_subsystem", opt: true, types: strL),
        ]
      ),
      Function(
        name: "shared_module",
        returnTypes: [BuildTgt()],
        args: [
          PositionalArgument(name: "target_name", types: strL),
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: true,
            types: [str, File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "c_args", opt: true, types: strlistL),
          Kwarg(name: "cpp_args", opt: true, types: strlistL),
          Kwarg(name: "cs_args", opt: true, types: strlistL),
          Kwarg(name: "cuda_args", opt: true, types: strlistL),
          Kwarg(name: "d_args", opt: true, types: strlistL),
          Kwarg(name: "fortran_args", opt: true, types: strlistL),
          Kwarg(name: "java_args", opt: true, types: strlistL),
          Kwarg(name: "objc_args", opt: true, types: strlistL),
          Kwarg(name: "objcpp_args", opt: true, types: strlistL),
          Kwarg(name: "rust_args", opt: true, types: strlistL),
          Kwarg(name: "vala_args", opt: true, types: strlistL),
          Kwarg(name: "cython_args", opt: true, types: strlistL),
          Kwarg(name: "nasm_args", opt: true, types: strlistL),
          Kwarg(name: "masm_args", opt: true, types: strlistL),
          Kwarg(name: "c_pch", opt: true, types: strL),
          Kwarg(name: "cpp_pch", opt: true, types: strL),
          Kwarg(name: "resources", opt: true, types: strL),
          Kwarg(name: "vala_header", opt: true, types: strL),
          Kwarg(name: "vala_vapi", opt: true, types: strL),
          Kwarg(name: "vala_gir", opt: true, types: strL),
          Kwarg(name: "build_by_default", opt: true, types: boolL),
          Kwarg(name: "build_rpath", opt: true, types: strL),
          Kwarg(name: "d_debug", opt: true, types: strlistL),
          Kwarg(name: "d_import_dirs", opt: true, types: strlistL),
          Kwarg(name: "d_module_versions", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "d_unittest", opt: true, types: boolL),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()])]),
          Kwarg(name: "extra_files", opt: true, types: [str, File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "gnu_symbol_visibility", opt: true, types: strL),
          Kwarg(name: "gui_app", opt: true, types: boolL),
          Kwarg(name: "implicit_include_directories", opt: true, types: boolL),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [str, Inc()])]),
          Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "install_rpath", opt: true, types: strL),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "link_args", opt: true, types: strlistL),
          Kwarg(name: "link_depends", opt: true, types: [str, File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "link_language", opt: true, types: strL),
          Kwarg(
            name: "link_whole",
            opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]
          ),
          Kwarg(
            name: "link_with",
            opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]
          ), Kwarg(name: "name_prefix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(
            name: "objects",
            opt: true,
            types: [ListType(types: [ExtractedObj(), File(), str])]
          ), Kwarg(name: "override_options", opt: true, types: strlistL),
          Kwarg(name: "rust_crate_type", opt: true, types: strL),
          Kwarg(
            name: "sources",
            opt: true,
            types: [str, File(), CustomTgt(), CustomIdx(), GeneratedList(), StructuredSrc()]
          ),
          Kwarg(name: "vs_module_defs", opt: true, types: [str, File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "win_subsystem", opt: true, types: strL),
        ]
      ),
      Function(
        name: "static_library",
        returnTypes: [Lib()],
        args: [
          PositionalArgument(name: "target_name", types: strL),
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: true,
            types: [str, File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "c_args", opt: true, types: strlistL),
          Kwarg(name: "cpp_args", opt: true, types: strlistL),
          Kwarg(name: "cs_args", opt: true, types: strlistL),
          Kwarg(name: "cuda_args", opt: true, types: strlistL),
          Kwarg(name: "d_args", opt: true, types: strlistL),
          Kwarg(name: "fortran_args", opt: true, types: strlistL),
          Kwarg(name: "java_args", opt: true, types: strlistL),
          Kwarg(name: "objc_args", opt: true, types: strlistL),
          Kwarg(name: "objcpp_args", opt: true, types: strlistL),
          Kwarg(name: "rust_args", opt: true, types: strlistL),
          Kwarg(name: "vala_args", opt: true, types: strlistL),
          Kwarg(name: "cython_args", opt: true, types: strlistL),
          Kwarg(name: "nasm_args", opt: true, types: strlistL),
          Kwarg(name: "masm_args", opt: true, types: strlistL),
          Kwarg(name: "c_pch", opt: true, types: strL),
          Kwarg(name: "cpp_pch", opt: true, types: strL),
          Kwarg(name: "resources", opt: true, types: strL),
          Kwarg(name: "vala_header", opt: true, types: strL),
          Kwarg(name: "vala_vapi", opt: true, types: strL),
          Kwarg(name: "vala_gir", opt: true, types: strL),
          Kwarg(name: "build_by_default", opt: true, types: boolL),
          Kwarg(name: "build_rpath", opt: true, types: strL),
          Kwarg(name: "d_debug", opt: true, types: strlistL),
          Kwarg(name: "d_import_dirs", opt: true, types: strlistL),
          Kwarg(name: "d_module_versions", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "d_unittest", opt: true, types: boolL),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()])]),
          Kwarg(name: "extra_files", opt: true, types: [str, File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "gnu_symbol_visibility", opt: true, types: strL),
          Kwarg(name: "gui_app", opt: true, types: boolL),
          Kwarg(name: "implicit_include_directories", opt: true, types: boolL),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [str, Inc()])]),
          Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "install_rpath", opt: true, types: strL),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "link_args", opt: true, types: strlistL),
          Kwarg(name: "link_depends", opt: true, types: [str, File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "link_language", opt: true, types: strL),
          Kwarg(
            name: "link_whole",
            opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]
          ),
          Kwarg(
            name: "link_with",
            opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]
          ), Kwarg(name: "name_prefix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(
            name: "objects",
            opt: true,
            types: [ListType(types: [ExtractedObj(), File(), str])]
          ), Kwarg(name: "override_options", opt: true, types: strlistL),
          Kwarg(name: "pic", opt: true, types: boolL),
          Kwarg(name: "prelink", opt: true, types: boolL),
          Kwarg(name: "rust_crate_type", opt: true, types: strL),
          Kwarg(
            name: "sources",
            opt: true,
            types: [str, File(), CustomTgt(), CustomIdx(), GeneratedList(), StructuredSrc()]
          ), Kwarg(name: "soversion", opt: true, types: sil),
          Kwarg(name: "version", opt: true, types: strL),
          Kwarg(name: "vs_module_defs", opt: true, types: [str, File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "win_subsystem", opt: true, types: strL),
        ]
      ),
      Function(
        name: "structured_sources",
        returnTypes: [StructuredSrc()],
        args: [
          PositionalArgument(
            name: "root",
            types: [ListType(types: [str, File(), CustomTgt(), CustomIdx(), GeneratedList()])]
          ),
          PositionalArgument(
            name: "additional",
            opt: true,
            types: [Dict(types: [str, File(), CustomTgt(), CustomIdx(), GeneratedList()])]
          ),
        ]
      ),
      Function(
        name: "subdir",
        args: [
          PositionalArgument(name: "dir_name", types: strL),
          Kwarg(name: "if_found", opt: true, types: [ListType(types: [Dep()])]),
        ]
      ), Function(name: "subdir_done"),
      Function(
        name: "subproject",
        returnTypes: [Subproject()],
        args: [
          PositionalArgument(name: "subproject_name", types: strL),
          Kwarg(name: "default_options", opt: true, types: strlistL),
          Kwarg(name: "required", opt: true, types: [boolt, Feature()]),
          Kwarg(name: "version", opt: true, types: strL),
        ]
      ),
      Function(
        name: "summary",
        args: [
          PositionalArgument(
            name: "key_or_dict",
            types: [
              str,
              Dict(types: [
                str, boolt, intt, Dep(), ExternalProgram(),
                ListType(types: [str, boolt, intt, Dep(), ExternalProgram()]),
              ]),
            ]
          ),
          PositionalArgument(
            name: "value",
            opt: true,
            types: [
              str, boolt, intt, Dep(), ExternalProgram(),
              ListType(types: [str, boolt, intt, Dep(), ExternalProgram()]),
            ]
          ), Kwarg(name: "bool_yn", opt: true, types: boolL),
          Kwarg(name: "list_sep", opt: true, types: strL),
          Kwarg(name: "section", opt: true, types: strL),
        ]
      ),
      Function(
        name: "test",
        args: [
          PositionalArgument(name: "name", types: strL),
          PositionalArgument(name: "executable", types: [Exe(), Jar(), ExternalProgram(), File()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [str, File(), Tgt()])]),
          Kwarg(name: "depends", opt: true, types: [ListType(types: [BuildTgt(), CustomTgt()])]),
          Kwarg(name: "env", opt: true, types: [str, ListType(types: strL), Dict(types: strL)]),
          Kwarg(name: "is_parallel", opt: true, types: boolL),
          Kwarg(name: "priority", opt: true, types: inttL),
          Kwarg(name: "protocol", opt: true, types: strL),
          Kwarg(name: "should_fail", opt: true, types: boolL),
          Kwarg(name: "suite", opt: true, types: [str, ListType(types: strL)]),
          Kwarg(name: "timeout", opt: true, types: inttL),
          Kwarg(name: "verbose", opt: true, types: boolL),
          Kwarg(name: "workdir", opt: true, types: strL),
        ]
      ), Function(name: "unset_variable", args: [PositionalArgument(name: "varname", types: strL)]),
      Function(
        name: "vcs_tag",
        returnTypes: [CustomTgt()],
        args: [
          Kwarg(
            name: "command",
            opt: true,
            types: [ListType(types: [Exe(), ExternalProgram(), CustomTgt(), File(), str])]
          ), Kwarg(name: "fallback", opt: true, types: strL), Kwarg(name: "input", types: strL),
          Kwarg(name: "output", types: strL), Kwarg(name: "replace_string", opt: true, types: strL),
        ]
      ),
      Function(
        name: "warning",
        args: [
          PositionalArgument(
            name: "message",
            types: [str, intt, boolt, ListType(types: silb), Dict(types: silb)]
          ),
          PositionalArgument(
            name: "msg",
            varargs: true,
            opt: true,
            types: [str, intt, boolt, ListType(types: silb), Dict(types: silb)]
          ),
        ]
      ),
    ]
    self.vtables = [:]
    self.initVtables()
  }

  func initVtables() {
    var t = self.types["any"]!
    self.vtables["any"] = []
    t = self.types["bool"]!
    self.vtables["bool"] = [
      Method(name: "to_int", parent: t, returnTypes: [`IntType`()]),
      Method(
        name: "to_string",
        parent: t,
        returnTypes: [Str()],
        args: [
          PositionalArgument(name: "true_str", opt: true, types: [Str()]),
          PositionalArgument(name: "false_str", opt: true, types: [Str()]),
        ]
      ),
    ]
    t = self.types["build_machine"]!
    self.vtables["build_machine"] = [
      Method(name: "cpu", parent: t, returnTypes: [Str()]),
      Method(name: "cpu_family", parent: t, returnTypes: [Str()]),
      Method(name: "endian", parent: t, returnTypes: [Str()]),
      Method(name: "system", parent: t, returnTypes: [Str()]),
    ]
    t = self.types["dict"]!
    self.vtables["dict"] = [
      Method(
        name: "get",
        parent: t,
        returnTypes: [`Any`()],
        args: [
          PositionalArgument(name: "key", types: [Str()]),
          PositionalArgument(name: "fallback", opt: true, types: [`Any`()]),
        ]
      ),
      Method(
        name: "has_key",
        parent: t,
        returnTypes: [`BoolType`()],
        args: [PositionalArgument(name: "key", types: [Str()])]
      ), Method(name: "keys", parent: t, returnTypes: [ListType(types: [Str()])]),
    ]
    t = self.types["host_machine"]!
    self.vtables["host_machine"] = []
    t = self.types["int"]!
    self.vtables["int"] = [
      Method(name: "is_even", parent: t, returnTypes: [BoolType()]),
      Method(name: "is_odd", parent: t, returnTypes: [BoolType()]),
      Method(name: "to_string", parent: t, returnTypes: [Str()]),
    ]
    t = self.types["list"]!
    self.vtables["list"] = [
      Method(
        name: "contains",
        parent: t,
        returnTypes: [BoolType()],
        args: [PositionalArgument(name: "item", types: [`Any`()])]
      ),
      Method(
        name: "get",
        parent: t,
        returnTypes: [`Any`()],
        args: [
          PositionalArgument(name: "index", types: [`IntType`()]),
          PositionalArgument(name: "fallback", opt: true, types: [`Any`()]),
        ]
      ), Method(name: "length", parent: t, returnTypes: [`IntType`()]),
    ]
    t = self.types["meson"]!
    self.vtables["meson"] = [
      Method(
        name: "add_devenv",
        parent: t,
        args: [
          PositionalArgument(
            name: "env",
            types: [
              Env(), Str(), ListType(types: [Str()]), Dict(types: [Str()]),
              Dict(types: [ListType(types: [Str()])]),
            ]
          ), Kwarg(name: "method", opt: true, types: [Str()]),
          Kwarg(name: "separator", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "add_dist_script",
        parent: t,
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
        parent: t,
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
        parent: t,
        args: [
          PositionalArgument(name: "script_name", types: [Str(), File(), ExternalProgram()]),
          PositionalArgument(
            name: "arg",
            varargs: true,
            opt: true,
            types: [Str(), File(), ExternalProgram()]
          ),
        ]
      ), Method(name: "backend", parent: t, returnTypes: [Str()]),
      Method(name: "build_root", parent: t, returnTypes: [Str()]),
      Method(name: "can_run_host_binaries", parent: t, returnTypes: [BoolType()]),
      Method(name: "current_build_dir", parent: t, returnTypes: [Str()]),
      Method(name: "current_source_dir", parent: t, returnTypes: [Str()]),
      Method(
        name: "get_compiler",
        parent: t,
        returnTypes: [Compiler()],
        args: [
          PositionalArgument(name: "language", types: [Str()]),
          Kwarg(name: "native", opt: true, types: [BoolType()]),
        ]
      ),
      Method(
        name: "get_cross_property",
        parent: t,
        returnTypes: [`Any`()],
        args: [
          PositionalArgument(name: "propname", types: [Str()]),
          PositionalArgument(name: "fallback_value", opt: true, types: [`Any`()]),
        ]
      ),
      Method(
        name: "get_external_property",
        parent: t,
        returnTypes: [`Any`()],
        args: [
          PositionalArgument(name: "propname", types: [Str()]),
          PositionalArgument(name: "fallback_value", opt: true, types: [`Any`()]),
          Kwarg(name: "native", opt: true, types: [BoolType()]),
        ]
      ), Method(name: "global_build_root", parent: t, returnTypes: [Str()]),
      Method(name: "global_source_root", parent: t, returnTypes: [Str()]),
      Method(name: "has_exe_wrapper", parent: t, returnTypes: [BoolType()]),
      Method(
        name: "has_external_property",
        parent: t,
        returnTypes: [BoolType()],
        args: [
          PositionalArgument(name: "propname", types: [Str()]),
          Kwarg(name: "native", opt: true, types: [BoolType()]),
        ]
      ),
      Method(
        name: "install_dependency_manifest",
        parent: t,
        args: [PositionalArgument(name: "output_name", types: [Str()])]
      ), Method(name: "is_cross_build", parent: t, returnTypes: [BoolType()]),
      Method(name: "is_subproject", parent: t, returnTypes: [BoolType()]),
      Method(name: "is_unity", parent: t, returnTypes: [BoolType()]),
      Method(
        name: "override_dependency",
        parent: t,
        args: [
          PositionalArgument(name: "name", types: [Str()]),
          PositionalArgument(name: "dep_object", types: [Dep()]),
          Kwarg(name: "native", opt: true, types: [BoolType()]),
          Kwarg(name: "static", opt: true, types: [BoolType()]),
        ]
      ),
      Method(
        name: "override_find_program",
        parent: t,
        args: [
          PositionalArgument(name: "progname", types: [Str()]),
          PositionalArgument(name: "program", types: [Exe(), File(), ExternalProgram()]),
        ]
      ), Method(name: "project_build_root", parent: t, returnTypes: [Str()]),
      Method(name: "project_license", parent: t, returnTypes: [ListType(types: [Str()])]),
      Method(name: "project_license_files", parent: t),
      Method(name: "project_name", parent: t, returnTypes: [Str()]),
      Method(name: "project_source_root", parent: t, returnTypes: [Str()]),
      Method(name: "project_version", parent: t, returnTypes: [Str()]),
      Method(name: "source_root", parent: t, returnTypes: [Str()]),
      Method(name: "version", parent: t, returnTypes: [Str()]),
    ]
    t = self.types["str"]!
    self.vtables["str"] = [
      Method(
        name: "contains",
        parent: t,
        returnTypes: [BoolType()],
        args: [PositionalArgument(name: "fragment", types: [t])]
      ),
      Method(
        name: "endswith",
        parent: t,
        returnTypes: [BoolType()],
        args: [PositionalArgument(name: "fragment", types: [t])]
      ),
      Method(
        name: "format",
        parent: t,
        returnTypes: [t],
        args: [
          PositionalArgument(name: "fmt", types: [t]),
          PositionalArgument(
            name: "value",
            varargs: true,
            opt: true,
            types: [`IntType`(), BoolType(), t]
          ),
        ]
      ),
      Method(
        name: "join",
        parent: t,
        returnTypes: [t],
        args: [PositionalArgument(name: "strings", varargs: true, opt: true, types: [t])]
      ),
      Method(
        name: "replace",
        parent: t,
        returnTypes: [t],
        args: [
          PositionalArgument(name: "old", types: [t]), PositionalArgument(name: "new", types: [t]),
        ]
      ),
      Method(
        name: "split",
        parent: t,
        returnTypes: [ListType(types: [t])],
        args: [PositionalArgument(name: "split_string", opt: true, types: [t])]
      ),
      Method(
        name: "startswith",
        parent: t,
        returnTypes: [BoolType()],
        args: [PositionalArgument(name: "fragment", types: [t])]
      ),
      Method(
        name: "strip",
        parent: t,
        returnTypes: [t],
        args: [PositionalArgument(name: "strip_chars", opt: true, types: [t])]
      ),
      Method(
        name: "substring",
        parent: t,
        returnTypes: [t],
        args: [
          PositionalArgument(name: "start", opt: true, types: [`IntType`()]),
          PositionalArgument(name: "end", opt: true, types: [`IntType`()]),
        ]
      ), Method(name: "to_int", parent: t, returnTypes: [`IntType`()]),
      Method(name: "to_lower", parent: t, returnTypes: [t]),
      Method(name: "to_upper", parent: t, returnTypes: [t]),
      Method(name: "underscorify", parent: t, returnTypes: [t]),
      Method(
        name: "version_compare",
        parent: t,
        returnTypes: [BoolType()],
        args: [PositionalArgument(name: "compare_string", types: [t])]
      ),
    ]
    t = self.types["target_machine"]!
    self.vtables["target_machine"] = []
    t = self.types["alias_tgt"]!
    self.vtables["alias_tgt"] = []
    t = self.types["both_libs"]!
    self.vtables["both_libs"] = [
      Method(name: "get_shared_lib", parent: t, returnTypes: [Lib()]),
      Method(name: "get_static_lib", parent: t, returnTypes: [Lib()]),
    ]
    t = self.types["build_tgt"]!
    self.vtables["build_tgt"] = [
      Method(
        name: "extract_all_objects",
        parent: t,
        returnTypes: [ExtractedObj()],
        args: [Kwarg(name: "recursive", opt: true, types: [ExtractedObj()])]
      ),
      Method(
        name: "extract_objects",
        parent: t,
        returnTypes: [ExtractedObj()],
        args: [
          PositionalArgument(name: "source", varargs: true, opt: true, types: [Str(), File()])
        ]
      ), Method(name: "found", parent: t, returnTypes: [BoolType()]),
      Method(name: "full_path", parent: t, returnTypes: [Str()]),
      // TODO: Is this an internal method?
      Method(name: "outdir", parent: t, returnTypes: [Str()]),
      Method(name: "name", parent: t, returnTypes: [Str()]),
      Method(name: "path", parent: t, returnTypes: [Str()]),
      Method(name: "private_dir_include", parent: t, returnTypes: [Inc()]),
    ]
    t = self.types["cfg_data"]!
    self.vtables["cfg_data"] = [
      Method(
        name: "get",
        parent: t,
        returnTypes: [BoolType(), Str(), `IntType`()],
        args: [
          PositionalArgument(name: "varname", types: [Str()]),
          PositionalArgument(
            name: "default_value",
            opt: true,
            types: [Str(), `IntType`(), BoolType()]
          ),
        ]
      ),
      Method(
        name: "get_unquoted",
        parent: t,
        returnTypes: [BoolType(), Str(), `IntType`()],
        args: [
          PositionalArgument(name: "varname", types: [Str()]),
          PositionalArgument(
            name: "default_value",
            opt: true,
            types: [Str(), `IntType`(), BoolType()]
          ),
        ]
      ),
      Method(
        name: "has",
        parent: t,
        returnTypes: [BoolType()],
        args: [PositionalArgument(name: "varname", types: [Str()])]
      ), Method(name: "keys", parent: t, returnTypes: [ListType(types: [Str()])]),
      Method(name: "merge_from", parent: t, args: [PositionalArgument(name: "other", types: [t])]),
      Method(
        name: "set",
        parent: t,
        args: [
          PositionalArgument(name: "varname", types: [Str()]),
          PositionalArgument(name: "value", types: [Str(), `IntType`(), BoolType()]),
          Kwarg(name: "description", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "set10",
        parent: t,
        args: [
          PositionalArgument(name: "varname", types: [Str()]),
          PositionalArgument(name: "value", types: [Str(), `IntType`(), BoolType()]),
          Kwarg(name: "description", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "set_quoted",
        parent: t,
        args: [
          PositionalArgument(name: "varname", types: [Str()]),
          PositionalArgument(name: "value", types: [Str(), `IntType`(), BoolType()]),
          Kwarg(name: "description", opt: true, types: [Str()]),
        ]
      ),
    ]
    t = self.types["compiler"]!
    self.vtables["compiler"] = [
      Method(
        name: "alignment",
        parent: t,
        returnTypes: [`IntType`()],
        args: [
          PositionalArgument(name: "typename", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: [Str()]), Str()]),
        ]
      ),
      Method(
        name: "check_header",
        parent: t,
        returnTypes: [BoolType()],
        args: [
          PositionalArgument(name: "header_name", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: [Str()]), Str()]),
          Kwarg(name: "required", opt: true, types: [BoolType(), Feature()]),
        ]
      ), Method(name: "cmd_array", parent: t, returnTypes: [ListType(types: [Str()])]),
      Method(
        name: "compiles",
        parent: t,
        returnTypes: [BoolType()],
        args: [
          PositionalArgument(name: "code", types: [Str(), File()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "name", opt: true, types: [Str()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
        ]
      ),
      Method(
        name: "compute_int",
        parent: t,
        returnTypes: [`IntType`()],
        args: [
          PositionalArgument(name: "expr", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "guess", opt: true, types: [`IntType`()]),
          Kwarg(name: "high", opt: true, types: [`IntType`()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "low", opt: true, types: [`IntType`()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: [Str()]), Str()]),
        ]
      ),
      Method(
        name: "find_library",
        parent: t,
        returnTypes: [Dep()],
        args: [
          PositionalArgument(name: "libname", types: [Str()]),
          Kwarg(name: "dirs", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "disabler", opt: true, types: [BoolType()]),
          Kwarg(name: "has_headers", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "header_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "header_dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(
            name: "header_include_directories",
            opt: true,
            types: [ListType(types: [Inc()]), Inc()]
          ), Kwarg(name: "header_no_builtin_args", opt: true, types: [BoolType()]),
          Kwarg(name: "header_prefix", opt: true, types: [Str()]),
          Kwarg(name: "required", opt: true, types: [BoolType(), Feature()]),
          Kwarg(name: "static", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "first_supported_argument",
        parent: t,
        returnTypes: [ListType(types: [Str()])],
        args: [PositionalArgument(name: "arg", varargs: true, opt: true, types: [Str()])]
      ),
      Method(
        name: "first_supported_link_argument",
        parent: t,
        returnTypes: [ListType(types: [Str()])],
        args: [PositionalArgument(name: "arg", varargs: true, opt: true, types: [Str()])]
      ), Method(name: "get_argument_syntax", parent: t, returnTypes: [Str()]),
      Method(
        name: "get_define",
        parent: t,
        returnTypes: [Str()],
        args: [
          PositionalArgument(name: "definename", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: [Str()]), Str()]),
        ]
      ), Method(name: "get_id", parent: t, returnTypes: [Str()]),
      Method(name: "get_linker_id", parent: t, returnTypes: [Str()]),
      Method(
        name: "get_supported_arguments",
        parent: t,
        returnTypes: [ListType(types: [Str()])],
        args: [
          PositionalArgument(name: "arg", varargs: true, opt: true, types: [Str()]),
          Kwarg(name: "checked", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "get_supported_function_attributes",
        parent: t,
        returnTypes: [ListType(types: [Str()])],
        args: [PositionalArgument(name: "attribs", varargs: true, opt: true, types: [Str()])]
      ),
      Method(
        name: "get_supported_link_arguments",
        parent: t,
        returnTypes: [ListType(types: [Str()])],
        args: [PositionalArgument(name: "arg", varargs: true, opt: true, types: [Str()])]
      ),
      Method(
        name: "has_argument",
        parent: t,
        returnTypes: [BoolType()],
        args: [PositionalArgument(name: "argument", types: [Str()])]
      ),
      Method(
        name: "has_function",
        parent: t,
        returnTypes: [BoolType()],
        args: [
          PositionalArgument(name: "funcname", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: [Str()]), Str()]),
        ]
      ),
      Method(
        name: "has_function_attribute",
        parent: t,
        returnTypes: [BoolType()],
        args: [PositionalArgument(name: "name", types: [Str()])]
      ),
      Method(
        name: "has_header",
        parent: t,
        returnTypes: [BoolType()],
        args: [
          PositionalArgument(name: "header_name", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: [Str()]), Str()]),
          Kwarg(name: "required", opt: true, types: [BoolType(), Feature()]),
        ]
      ),
      Method(
        name: "has_header_symbol",
        parent: t,
        returnTypes: [BoolType()],
        args: [
          PositionalArgument(name: "header", types: [Str()]),
          PositionalArgument(name: "symbol", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: [Str()]), Str()]),
          Kwarg(name: "required", opt: true, types: [BoolType(), Feature()]),
        ]
      ),
      Method(
        name: "has_link_argument",
        parent: t,
        returnTypes: [BoolType()],
        args: [PositionalArgument(name: "argument", types: [Str()])]
      ),
      Method(
        name: "has_member",
        parent: t,
        returnTypes: [BoolType()],
        args: [
          PositionalArgument(name: "typename", types: [Str()]),
          PositionalArgument(name: "membername", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: [Str()]), Str()]),
        ]
      ),
      Method(
        name: "has_members",
        parent: t,
        returnTypes: [BoolType()],
        args: [
          PositionalArgument(name: "typename", types: [Str()]),
          PositionalArgument(name: "member", varargs: true, types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: [Str()]), Str()]),
        ]
      ),
      Method(
        name: "has_multi_arguments",
        parent: t,
        returnTypes: [BoolType()],
        args: [PositionalArgument(name: "arg", varargs: true, opt: true, types: [Str()])]
      ),
      Method(
        name: "has_multi_link_arguments",
        parent: t,
        returnTypes: [BoolType()],
        args: [PositionalArgument(name: "arg", varargs: true, opt: true, types: [Str()])]
      ),
      Method(
        name: "has_type",
        parent: t,
        returnTypes: [BoolType()],
        args: [
          PositionalArgument(name: "typename", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: [Str()]), Str()]),
        ]
      ),
      Method(
        name: "links",
        parent: t,
        returnTypes: [BoolType()],
        args: [
          PositionalArgument(name: "source", types: [Str(), File()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "name", opt: true, types: [Str()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
        ]
      ),
      Method(
        name: "preprocess",
        parent: t,
        returnTypes: [ListType(types: [CustomIdx()])],
        args: [
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "compile_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "output", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "run",
        parent: t,
        returnTypes: [RunResult()],
        args: [
          PositionalArgument(name: "code", types: [Str(), File()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "name", opt: true, types: [Str()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
        ]
      ),
      Method(
        name: "sizeof",
        parent: t,
        returnTypes: [`IntType`()],
        args: [
          PositionalArgument(name: "typename", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "name", opt: true, types: [Str()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: [Str()]), Str()]),
        ]
      ), Method(name: "symbols_have_underscore_prefix", parent: t, returnTypes: [BoolType()]),
      Method(name: "version", parent: t, returnTypes: [Str()]),
    ]
    t = self.types["custom_idx"]!
    self.vtables["custom_idx"] = [Method(name: "full_path", parent: t, returnTypes: [Str()])]
    t = self.types["custom_tgt"]!
    self.vtables["custom_tgt"] = [
      Method(name: "index", parent: t, returnTypes: [CustomIdx()]),
      Method(name: "full_path", parent: t, returnTypes: [Str()]),
      Method(name: "to_list", parent: t, returnTypes: [ListType(types: [CustomIdx()])]),
    ]
    t = self.types["dep"]!
    self.vtables["dep"] = [
      Method(name: "as_link_whole", parent: t, returnTypes: [t]),
      Method(
        name: "as_system",
        parent: t,
        returnTypes: [t],
        args: [PositionalArgument(name: "value", varargs: false, opt: true, types: [Str()])]
      ), Method(name: "found", parent: t, returnTypes: [BoolType()]),
      Method(
        name: "get_configtool_variable",
        parent: t,
        returnTypes: [Str()],
        args: [PositionalArgument(name: "var_name", types: [Str()])]
      ),
      Method(
        name: "get_pkgconfig_variable",
        parent: t,
        returnTypes: [Str()],
        args: [
          PositionalArgument(name: "var_name", types: [Str()]),
          Kwarg(name: "default", opt: true, types: [Str()]),
          Kwarg(name: "define_variable", opt: true, types: [ListType(types: [Str()])]),
        ]
      ),
      Method(
        name: "get_variable",
        parent: t,
        returnTypes: [Str()],
        args: [
          PositionalArgument(name: "varname", opt: true, types: [Str()]),
          Kwarg(name: "cmake", opt: true, types: [Str()]),
          Kwarg(name: "configtool", opt: true, types: [Str()]),
          Kwarg(name: "default_value", opt: true, types: [Str()]),
          Kwarg(name: "internal", opt: true, types: [Str()]),
          Kwarg(name: "pkgconfig", opt: true, types: [Str()]),
          Kwarg(name: "pkgconfig_define", opt: true, types: [ListType(types: [Str()])]),
        ]
      ), Method(name: "include_type", parent: t, returnTypes: [Str()]),
      Method(name: "name", parent: t, returnTypes: [Str()]),
      Method(
        name: "partial_dependency",
        parent: t,
        returnTypes: [t],
        args: [
          Kwarg(name: "compile_args", opt: true, types: [BoolType()]),
          Kwarg(name: "includes", opt: true, types: [BoolType()]),
          Kwarg(name: "link_args", opt: true, types: [BoolType()]),
          Kwarg(name: "links", opt: true, types: [BoolType()]),
          Kwarg(name: "sources", opt: true, types: [BoolType()]),
        ]
      ), Method(name: "type_name", parent: t, returnTypes: [Str()]),
      Method(name: "version", parent: t, returnTypes: [Str()]),
    ]
    t = self.types["disabler"]!
    self.vtables["disabler"] = [Method(name: "found", parent: t, returnTypes: [BoolType()])]
    t = self.types["env"]!
    self.vtables["env"] = [
      Method(
        name: "append",
        parent: t,
        args: [
          PositionalArgument(name: "variable", types: [Str()]),
          PositionalArgument(name: "value", varargs: true, opt: true, types: [Str()]),
          Kwarg(name: "separator", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "prepend",
        parent: t,
        args: [
          PositionalArgument(name: "variable", types: [Str()]),
          PositionalArgument(name: "value", varargs: true, opt: true, types: [Str()]),
          Kwarg(name: "separator", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "set",
        parent: t,
        args: [
          PositionalArgument(name: "variable", types: [Str()]),
          PositionalArgument(name: "value", varargs: true, opt: true, types: [Str()]),
          Kwarg(name: "separator", opt: true, types: [Str()]),
        ]
      ),
    ]
    t = self.types["exe"]!
    self.vtables["exe"] = []
    t = self.types["external_program"]!
    self.vtables["external_program"] = [
      Method(name: "found", parent: t, returnTypes: [BoolType()]),
      Method(name: "full_path", parent: t, returnTypes: [Str()]),
      Method(name: "path", parent: t, returnTypes: [Str()]),
      Method(name: "version", parent: t, returnTypes: [Str()]),
    ]
    t = self.types["extracted_obj"]!
    self.vtables["extracted_obj"] = []
    t = self.types["feature"]!
    self.vtables["feature"] = [
      Method(name: "allowed", parent: t, returnTypes: [BoolType()]),
      Method(name: "auto", parent: t, returnTypes: [BoolType()]),
      Method(
        name: "disable_auto_if",
        parent: t,
        returnTypes: [t],
        args: [PositionalArgument(name: "value", types: [BoolType()])]
      ), Method(name: "disabled", parent: t, returnTypes: [BoolType()]),
      Method(name: "enabled", parent: t, returnTypes: [BoolType()]),
      Method(
        name: "require",
        parent: t,
        returnTypes: [t],
        args: [
          PositionalArgument(name: "value", types: [BoolType()]),
          Kwarg(name: "error_message", opt: true, types: [Str()]),
        ]
      ),
    ]
    t = self.types["file"]!
    self.vtables["file"] = []
    t = self.types["generated_list"]!
    self.vtables["generated_list"] = []
    t = self.types["generator"]!
    self.vtables["generator"] = [
      Method(
        name: "process",
        parent: t,
        returnTypes: [GeneratedList()],
        args: [
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: false,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "extra_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "preserve_path_from", opt: true, types: [Str()]),
        ]
      )
    ]
    t = self.types["inc"]!
    self.vtables["inc"] = []
    t = self.types["jar"]!
    self.vtables["jar"] = []
    t = self.types["lib"]!
    self.vtables["lib"] = []
    t = self.types["module"]!
    self.vtables["module"] = [Method(name: "found", parent: t, returnTypes: [BoolType()])]
    t = self.types["range"]!
    self.vtables["range"] = []
    t = self.types["runresult"]!
    self.vtables["runresult"] = [
      Method(name: "compiled", parent: t, returnTypes: [BoolType()]),
      Method(name: "returncode", parent: t, returnTypes: [`IntType`()]),
      Method(name: "stderr", parent: t, returnTypes: [Str()]),
      Method(name: "stdout", parent: t, returnTypes: [Str()]),
    ]
    t = self.types["run_tgt"]!
    self.vtables["run_tgt"] = []
    t = self.types["structured_src"]!
    self.vtables["structured_src"] = []
    t = self.types["subproject"]!
    self.vtables["subproject"] = [
      Method(name: "found", parent: t, returnTypes: [BoolType()]),
      Method(
        name: "get_variable",
        parent: t,
        returnTypes: [`Any`()],
        args: [
          PositionalArgument(name: "var_name", types: [Str()]),
          PositionalArgument(name: "fallback", opt: true, types: [`Any`()]),
        ]
      ),
    ]
    t = self.types["tgt"]!
    self.vtables["tgt"] = []
    t = self.types["cmake_module"]!
    self.vtables["cmake_module"] = [
      Method(
        name: "subproject",
        parent: t,
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
        parent: t,
        returnTypes: [CMakeSubprojectOptions()],
        args: []
      ),
      Method(
        name: "write_basic_package_version_file",
        parent: t,
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
        parent: t,
        returnTypes: [],
        args: [
          Kwarg(name: "name", types: [Str()]), Kwarg(name: "input", types: [Str(), File()]),
          Kwarg(name: "configuration", types: [CfgData()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
        ]
      ),
    ]
    t = self.types["cmake_subproject"]!
    self.vtables["cmake_subproject"] = [
      Method(
        name: "dependency",
        parent: t,
        returnTypes: [Dep()],
        args: [
          PositionalArgument(name: "tgt", types: [CMakeTarget()]),
          Kwarg(name: "include_type", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "include_directories",
        parent: t,
        returnTypes: [Inc()],
        args: [PositionalArgument(name: "tgt", types: [CMakeTarget()])]
      ),
      Method(
        name: "target",
        parent: t,
        returnTypes: [Tgt()],
        args: [PositionalArgument(name: "tgt", types: [CMakeTarget()])]
      ),
      Method(
        name: "target_type",
        parent: t,
        returnTypes: [Str()],
        args: [PositionalArgument(name: "tgt", types: [CMakeTarget()])]
      ), Method(name: "target_list", parent: t, returnTypes: [ListType(types: [Str()])], args: []),
      Method(name: "found", parent: t, returnTypes: [BoolType()]),
      Method(
        name: "get_variable",
        parent: t,
        returnTypes: [`Any`()],
        args: [
          PositionalArgument(name: "var_name", types: [Str()]),
          PositionalArgument(name: "fallback", opt: true, types: [`Any`()]),
        ]
      ),
    ]
    t = self.types["cmake_subprojectoptions"]!
    self.vtables["cmake_subprojectoptions"] = [
      Method(
        name: "add_cmake_defines",
        parent: t,
        returnTypes: [],
        args: [PositionalArgument(name: "defines", types: [Dict(types: [Str()])])]
      ),
      Method(
        name: "set_override_option",
        parent: t,
        returnTypes: [],
        args: [
          PositionalArgument(name: "opt", types: [Str()]),
          PositionalArgument(name: "val", types: [Str()]),
          Kwarg(name: "target", opt: true, types: [CMakeTarget()]),
        ]
      ),
      Method(
        name: "set_install",
        parent: t,
        returnTypes: [],
        args: [
          PositionalArgument(name: "install", types: [BoolType()]),
          Kwarg(name: "target", opt: true, types: [CMakeTarget()]),
        ]
      ),
      Method(
        name: "append_compile_args",
        parent: t,
        returnTypes: [],
        args: [
          PositionalArgument(name: "language", types: [Str()]),
          PositionalArgument(name: "arg", varargs: true, types: [Str()]),
          Kwarg(name: "target", opt: true, types: [CMakeTarget()]),
        ]
      ),
      Method(
        name: "append_link_args",
        parent: t,
        returnTypes: [],
        args: [
          PositionalArgument(name: "language", types: [Str()]),
          PositionalArgument(name: "arg", varargs: true, types: [Str()]),
          Kwarg(name: "target", opt: true, types: [CMakeTarget()]),
        ]
      ), Method(name: "clear", parent: t, returnTypes: [], args: []),
    ]
    t = self.types["cmake_tgt"]!
    self.vtables["cmake_tgt"] = []
    t = self.types["cuda_module"]!
    self.vtables["cuda_module"] = [
      Method(
        name: "min_driver_version",
        parent: t,
        returnTypes: [Str()],
        args: [PositionalArgument(name: "version_string", varargs: true, types: [Str()])]
      ),
      Method(
        name: "nvcc_arch_flags",
        parent: t,
        returnTypes: [ListType(types: [Str()])],
        args: [
          PositionalArgument(name: "architecture_set", varargs: true, opt: true, types: [Str()]),
          Kwarg(name: "detected", opt: true, types: [Str(), ListType(types: [Str()])]),
        ]
      ),
      Method(
        name: "nvcc_arch_readable",
        parent: t,
        returnTypes: [ListType(types: [Str()])],
        args: [
          PositionalArgument(name: "architecture_set", varargs: true, opt: true, types: [Str()]),
          Kwarg(name: "detected", opt: true, types: [Str(), ListType(types: [Str()])]),
        ]
      ),
    ]
    t = self.types["dlang_module"]!
    self.vtables["dlang_module"] = [
      Method(
        name: "generate_dub_file",
        parent: t,
        returnTypes: [],
        args: [
          PositionalArgument(name: "name", types: [Str()]),
          PositionalArgument(name: "source", types: [Str()]),
          Kwarg(name: "authors", opt: true, types: [Str(), ListType(types: [Str()])]),
          Kwarg(name: "description", opt: true, types: [Str()]),
          // TODO: Derived just based on guessing
          Kwarg(name: "copyright", opt: true, types: [Str(), ListType(types: [Str()])]),
          Kwarg(name: "license", opt: true, types: [Str(), ListType(types: [Str()])]),
          Kwarg(name: "sourceFiles", opt: true, types: [Str(), ListType(types: [Str()])]),
          Kwarg(name: "targetType", opt: true, types: [Str()]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep(), Str()])]),
        ]
      )
    ]
    t = self.types["external_project"]!
    self.vtables["external_project"] = [
      Method(
        name: "dependency",
        parent: t,
        returnTypes: [Dep()],
        args: [
          PositionalArgument(name: "subdir", types: [Str()]),
          Kwarg(name: "subdir", opt: true, types: [Str()]),
        ]
      )
    ]
    t = self.types["external_project_module"]!
    self.vtables["external_project_module"] = [
      Method(
        name: "add_project",
        parent: t,
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
    t = self.types["fs_module"]!
    self.vtables["fs_module"] = [
      Method(
        name: "exists",
        parent: t,
        returnTypes: [BoolType()],
        args: [PositionalArgument(name: "file", types: [Str()])]
      ),
      Method(
        name: "is_dir",
        parent: t,
        returnTypes: [BoolType()],
        args: [PositionalArgument(name: "file", types: [Str()])]
      ),
      Method(
        name: "is_file",
        parent: t,
        returnTypes: [BoolType()],
        args: [PositionalArgument(name: "file", types: [Str()])]
      ),
      Method(
        name: "is_symlink",
        parent: t,
        returnTypes: [BoolType()],
        args: [PositionalArgument(name: "file", types: [Str(), File()])]
      ),
      Method(
        name: "is_absolute",
        parent: t,
        returnTypes: [BoolType()],
        args: [PositionalArgument(name: "file", types: [Str()])]
      ),
      Method(
        name: "hash",
        parent: t,
        returnTypes: [Str()],
        args: [
          PositionalArgument(name: "file", types: [Str(), File()]),
          PositionalArgument(name: "hash_algorithm", types: [Str()]),
        ]
      ),
      Method(
        name: "size",
        parent: t,
        returnTypes: [`IntType`()],
        args: [PositionalArgument(name: "file", types: [Str(), File()])]
      ),
      Method(
        name: "is_samepath",
        parent: t,
        returnTypes: [Str()],
        args: [
          PositionalArgument(name: "path1", types: [Str(), File()]),
          PositionalArgument(name: "path2", types: [Str(), File()]),
        ]
      ),
      Method(
        name: "expanduser",
        parent: t,
        returnTypes: [Str()],
        args: [PositionalArgument(name: "file", types: [Str()])]
      ),
      Method(
        name: "as_posix",
        parent: t,
        returnTypes: [Str()],
        args: [PositionalArgument(name: "file", types: [Str()])]
      ),
      Method(
        name: "replace_suffix",
        parent: t,
        returnTypes: [Str()],
        args: [
          PositionalArgument(name: "file", types: [Str()]),
          PositionalArgument(name: "suffix", types: [Str()]),
        ]
      ),
      Method(
        name: "parent",
        parent: t,
        returnTypes: [Str()],
        args: [PositionalArgument(name: "file", types: [File(), Str()])]
      ),
      Method(
        name: "name",
        parent: t,
        returnTypes: [Str()],
        args: [PositionalArgument(name: "file", types: [File(), Str()])]
      ),
      Method(
        name: "stem",
        parent: t,
        returnTypes: [Str()],
        args: [PositionalArgument(name: "file", types: [File(), Str()])]
      ),
      Method(
        name: "read",
        parent: t,
        returnTypes: [Str()],
        args: [
          PositionalArgument(name: "file", types: [File(), Str()]),
          Kwarg(name: "encoding", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "copyfile",
        parent: t,
        returnTypes: [CustomTgt()],
        args: [
          PositionalArgument(name: "src", types: [File(), Str()]),
          PositionalArgument(name: "dst", opt: true, types: [Str()]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_tag", opt: true, types: [Str()]),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
        ]
      ),
    ]
    t = self.types["gnome_module"]!
    self.vtables["gnome_module"] = [
      Method(
        name: "compile_resources",
        parent: t,
        returnTypes: [ListType(types: [BuildTgt()])],
        args: [
          PositionalArgument(name: "id", types: [Str()]),
          PositionalArgument(
            name: "input",
            types: [ListType(types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()])]
          ), Kwarg(name: "c_name", opt: true, types: [Str()]),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [File(), CustomTgt(), CustomIdx()])]
          ), Kwarg(name: "export", opt: true, types: [BoolType()]),
          Kwarg(name: "extra_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "gresource_bundle", opt: true, types: [BoolType()]),
          Kwarg(name: "build_by_default", opt: true, types: [BoolType()]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_header", opt: true, types: [BoolType()]),
          Kwarg(name: "source_dir", opt: true, types: [ListType(types: [Str()])]),
        ]
      ),
      Method(
        name: "generate_gir",
        parent: t,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          PositionalArgument(name: "file", varargs: true, types: [Exe(), Lib()]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()])]),
          Kwarg(name: "extra_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "export_packages", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(
            name: "sources",
            opt: true,
            types: [ListType(types: [Str(), File(), CustomTgt(), CustomIdx()])]
          ), Kwarg(name: "nsversion", opt: true, types: [Str()]),
          Kwarg(name: "namespace", opt: true, types: [Str()]),
          Kwarg(name: "identifier_prefix", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "includes", opt: true, types: [ListType(types: [Str(), CustomTgt()])]),
          Kwarg(name: "header", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "symbol_prefix", opt: true, types: [Str()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Str(), Inc()])]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "install_gir", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir_gir", opt: true, types: [Str(), BoolType()]),
          Kwarg(name: "install_typelib", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir_typelib", opt: true, types: [Str(), BoolType()]),
          Kwarg(name: "link_with", opt: true, types: [ListType(types: [Lib()])]),
          Kwarg(name: "symbok_prefix", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "fatal_warnings", opt: true, types: [BoolType()]),
          Kwarg(name: "build_by_default", opt: true, types: [BoolType()]),
        ]
      ),
      Method(
        name: "genmarshal",
        parent: t,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          PositionalArgument(name: "basename", types: [Str()]),
          Kwarg(name: "depends", opt: true, types: [ListType(types: [BuildTgt(), CustomTgt()])]),
          Kwarg(name: "depend_files", opt: true, types: [Str(), File()]),
          Kwarg(name: "extra_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_header", opt: true, types: [BoolType()]),
          Kwarg(name: "internal", opt: true, types: [BoolType()]),
          Kwarg(name: "nostdinc", opt: true, types: [BoolType()]),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "skip_source", opt: true, types: [BoolType()]),
          Kwarg(name: "sources", types: [ListType(types: [Str(), File()])]),
          Kwarg(name: "stdinc", opt: true, types: [BoolType()]),
          Kwarg(name: "valist_marshallers", opt: true, types: [BoolType()]),
        ]
      ),
      Method(
        name: "mkenums",
        parent: t,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          PositionalArgument(name: "name", types: [Str()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_header", opt: true, types: [BoolType()]),
          Kwarg(
            name: "sources",
            types: [ListType(types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()])]
          ), Kwarg(name: "symbol_prefix", opt: true, types: [Str()]),
          Kwarg(name: "identifier_prefix", opt: true, types: [Str()]),
          Kwarg(name: "depends", opt: true, types: [ListType(types: [BuildTgt(), CustomTgt()])]),
          Kwarg(name: "c_template", opt: true, types: [File(), Str()]),
          Kwarg(name: "h_template", opt: true, types: [File(), Str()]),
          Kwarg(name: "comments", opt: true, types: [Str()]),
          Kwarg(name: "eprod", opt: true, types: [Str()]),
          Kwarg(name: "fhead", opt: true, types: [Str()]),
          Kwarg(name: "fprod", opt: true, types: [Str()]),
          Kwarg(name: "ftail", opt: true, types: [Str()]),
          Kwarg(name: "vhead", opt: true, types: [Str()]),
          Kwarg(name: "vprod", opt: true, types: [Str()]),
          Kwarg(name: "vtail", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "mkenums_simple",
        parent: t,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          PositionalArgument(name: "name", types: [Str()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_header", opt: true, types: [BoolType()]),
          Kwarg(
            name: "sources",
            types: [ListType(types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()])]
          ), Kwarg(name: "symbol_prefix", opt: true, types: [Str()]),
          Kwarg(name: "identifier_prefix", opt: true, types: [Str()]),
          Kwarg(name: "body_prefix", opt: true, types: [Str()]),
          Kwarg(name: "decorator", opt: true, types: [Str()]),
          Kwarg(name: "function_prefix", opt: true, types: [Str()]),
          Kwarg(name: "header_prefix", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "compile_schemas",
        parent: t,
        returnTypes: [CustomTgt()],
        args: [
          Kwarg(name: "build_by_default", opt: true, types: [BoolType()]),
          Kwarg(name: "depend_files", opt: true, types: [Str(), File()]),
        ]
      ),
      Method(
        name: "gdbus_codegen",
        parent: t,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          PositionalArgument(name: "name", types: [Str()]),
          PositionalArgument(
            name: "file",
            varargs: true,
            opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "extra_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "interface_prefix", opt: true, types: [Str()]),
          Kwarg(name: "namespace", opt: true, types: [Str()]),
          Kwarg(name: "object_manager", opt: true, types: [BoolType()]),
          Kwarg(
            name: "annotations",
            opt: true,
            types: [ListType(types: [ListType(types: [Str()])])]
          ), Kwarg(name: "install_header", opt: true, types: [BoolType()]),
          Kwarg(name: "docbook", opt: true, types: [Str()]),
          Kwarg(name: "autocleanup", opt: true, types: [Str()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(
            name: "sources",
            opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ),
        ]
      ),
      Method(
        name: "generate_vapi",
        parent: t,
        returnTypes: [Dep()],
        args: [
          PositionalArgument(name: "name", types: [Str()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "sources", types: [ListType(types: [Str(), CustomTgt()])]),
          Kwarg(name: "vapi_dirs", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "metadata_dirs", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "gir_dirs", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "packages", opt: true, types: [ListType(types: [Str(), Dep()])]),
        ]
      ),
      Method(
        name: "yelp",
        parent: t,
        returnTypes: [],
        args: [
          PositionalArgument(name: "name", types: [Str()]),
          PositionalArgument(name: "file", varargs: true, opt: true, types: [Str()]),
          Kwarg(name: "languages", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "media", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "sources", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "symlink_media", opt: true, types: [BoolType()]),
        ]
      ),
      Method(
        name: "gtkdoc",
        parent: t,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          PositionalArgument(name: "name", types: [Str()]),
          Kwarg(name: "c_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "check", opt: true, types: [BoolType()]),
          Kwarg(
            name: "content_files",
            opt: true,
            types: [ListType(types: [Str(), File(), GeneratedList(), CustomTgt(), CustomIdx()])]
          ), Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep(), Lib()])]),
          Kwarg(
            name: "expand_content_files",
            opt: true,
            types: [ListType(types: [Str(), File()])]
          ), Kwarg(name: "fixref_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "gobject_typesfile", opt: true, types: [ListType(types: [Str(), File()])]),
          Kwarg(name: "html_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "html_assets", opt: true, types: [ListType(types: [Str(), File()])]),
          Kwarg(name: "ignore_headers", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Str(), Inc()])]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "main_sgml", opt: true, types: [Str()]),
          Kwarg(name: "main_xml", opt: true, types: [Str()]),
          Kwarg(name: "fixxref_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "mkdb_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "mode", opt: true, types: [Str()]),
          Kwarg(name: "module_version", opt: true, types: [Str()]),
          Kwarg(name: "namespace", opt: true, types: [Str()]),
          Kwarg(name: "scan_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "scanobj_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "src_dir", opt: true, types: [ListType(types: [Str(), Inc()])]),
        ]
      ),
      Method(
        name: "gtkdoc_html_dir",
        parent: t,
        returnTypes: [Str()],
        args: [PositionalArgument(name: "name", types: [Str()])]
      ),
      Method(
        name: "post_install",
        parent: t,
        returnTypes: [],
        args: [
          Kwarg(name: "glib_compile_schemas", opt: true, types: [BoolType()]),
          Kwarg(name: "gtk_update_icon_cache", opt: true, types: [BoolType()]),
          Kwarg(name: "update_desktop_database", opt: true, types: [BoolType()]),
          Kwarg(name: "update_mime_database", opt: true, types: [BoolType()]),
          Kwarg(name: "gio_querymodules", opt: true, types: [ListType(types: [Str()])]),
        ]
      ),
    ]
    t = self.types["hotdoc_module"]!
    self.vtables["hotdoc_module"] = [
      Method(
        name: "has_extensions",
        parent: t,
        returnTypes: [BoolType()],
        args: [PositionalArgument(name: "extensions", varargs: true, types: [Str()])]
      ),
      Method(
        name: "generate_doc",
        parent: t,
        returnTypes: [HotdocTarget()],
        args: [
          PositionalArgument(name: "project_name", types: [Str()]),
          Kwarg(name: "sitemap", types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "index", types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "project_version", types: [Str()]),
          Kwarg(
            name: "html_extra_theme",
            opt: true,
            types: [

            ]
          ), Kwarg(name: "include_paths", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [Str(), Lib(), CustomTgt(), CustomIdx()])]
          ),
          Kwarg(name: "depends", opt: true, types: [ListType(types: [CustomTgt(), CustomIdx()])]),
          Kwarg(name: "gi_c_source_roots", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "extra_assets", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "extra_extension_paths", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "subprojects", opt: true, types: [ListType(types: [HotdocTarget()])]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
        ]
      ),
    ]
    t = self.types["hotdoc_target"]!
    self.vtables["hotdoc_target"] = [Method(name: "config_path", parent: t, returnTypes: [Str()])]
    t = self.types["i18n_module"]!
    self.vtables["i18n_module"] = [
      Method(
        name: "gettext",
        parent: t,
        returnTypes: [ListType(types: [ListType(types: [CustomTgt()]), RunTgt()])],
        args: [
          PositionalArgument(name: "packagename", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "data_dirs", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "preset", opt: true, types: [Str()]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "languages", opt: true, types: [ListType(types: [Str()])]),
        ]
      ),
      Method(
        name: "merge_file",
        parent: t,
        returnTypes: [CustomTgt()],
        args: [
          Kwarg(name: "output", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "data_dirs", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "po_dir", types: [Str()]), Kwarg(name: "type", opt: true, types: [Str()]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_tag", opt: true, types: [Str()]),
          Kwarg(
            name: "input",
            opt: true,
            types: [
              ListType(types: [
                Str(), File(), ExternalProgram(), BuildTgt(), CustomTgt(), CustomIdx(),
                ExtractedObj(), GeneratedList(),
              ])
            ]
          ),
        ]
      ),
      Method(
        name: "itstool_join",
        parent: t,
        returnTypes: [CustomTgt()],
        args: [
          Kwarg(name: "output", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "data_dirs", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "mo_targets", types: [ListType(types: [CustomTgt()])]),
          Kwarg(name: "its_files", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "type", opt: true, types: [Str()]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_tag", opt: true, types: [Str()]),
          Kwarg(
            name: "input",
            opt: true,
            types: [
              ListType(types: [
                Str(), File(), ExternalProgram(), BuildTgt(), CustomTgt(), CustomIdx(),
                ExtractedObj(), GeneratedList(),
              ])
            ]
          ),
        ]
      ),
    ]
    t = self.types["icestorm_module"]!
    self.vtables["icestorm_module"] = [
      Method(
        name: "project",
        parent: t,
        returnTypes: [ListType(types: [RunTgt(), CustomTgt()])],
        args: [
          PositionalArgument(name: "project_name", types: [Str()]),
          PositionalArgument(
            name: "files",
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ),
          Kwarg(
            name: "constraint_file",
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ),
        ]
      )
    ]
    t = self.types["java_module"]!
    self.vtables["java_module"] = [
      Method(
        name: "generate_native_header",
        parent: t,
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
        parent: t,
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
        parent: t,
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
    t = self.types["keyval_module"]!
    self.vtables["keyval_module"] = [
      Method(
        name: "load",
        parent: t,
        returnTypes: [Dict(types: [Str()])],
        args: [PositionalArgument(name: "file", types: [File(), Str()])]
      )
    ]
    t = self.types["pkgconfig_module"]!
    self.vtables["pkgconfig_module"] = [
      Method(
        name: "generate",
        parent: t,
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
    t = self.types["python_module"]!
    self.vtables["python_module"] = [
      Method(
        name: "find_installation",
        parent: t,
        returnTypes: [PythonInstallation()],
        args: [
          PositionalArgument(name: "name_or_path", opt: true, types: [Str()]),
          Kwarg(name: "required", opt: true, types: [BoolType()]),
          Kwarg(name: "disabler", opt: true, types: [BoolType()]),
          Kwarg(name: "modules", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "pure", opt: true, types: [BoolType()]),
        ]
      )
    ]
    t = self.types["python_installation"]!
    self.vtables["python_installation"] = [
      Method(name: "path", parent: t, returnTypes: [Str()], args: []),
      Method(
        name: "extension_module",
        parent: t,
        returnTypes: [BuildTgt()],
        args: [
          PositionalArgument(name: "target_name", types: [Str()]),
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "c_args", opt: true, types: [ListType(types: [Str()])]),
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
            name: "d_module_versions",
            opt: true,
            types: [ListType(types: [Str(), `IntType`()])]
          ), Kwarg(name: "d_unittest", opt: true, types: [BoolType()]),
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
            name: "link_whole",
            opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]
          ),
          Kwarg(
            name: "link_with",
            opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]
          ), Kwarg(name: "native", opt: true, types: [BoolType()]),
          Kwarg(
            name: "objects",
            opt: true,
            types: [ListType(types: [ExtractedObj(), File(), Str()])]
          ), Kwarg(name: "override_options", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "rust_crate_type", opt: true, types: [Str()]),
          Kwarg(
            name: "sources",
            opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList(), StructuredSrc()]
          ),
          Kwarg(
            name: "vs_module_defs",
            opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx()]
          ), Kwarg(name: "win_subsystem", opt: true, types: [Str()]),
          Kwarg(name: "subdir", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "dependency",
        parent: t,
        returnTypes: [Dep()],
        args: [
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
          Kwarg(name: "disabler", opt: true, types: [BoolType()]),
          Kwarg(name: "embed", opt: true, types: [BoolType()]),
        ]
      ),
      Method(
        name: "install_sources",
        parent: t,
        returnTypes: [],
        args: [
          PositionalArgument(name: "file", varargs: true, opt: true, types: [Str(), File()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
          Kwarg(name: "install_tag", opt: true, types: [Str()]),
          Kwarg(name: "preserve_path", opt: true, types: [BoolType()]),
          Kwarg(name: "rename", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "sources", opt: true, types: [ListType(types: [File(), Str()])]),
          Kwarg(name: "pure", opt: true, types: [BoolType()]),
          Kwarg(name: "subdir", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "get_install_dir",
        parent: t,
        returnTypes: [Str()],
        args: [
          Kwarg(name: "pure", opt: true, types: [BoolType()]),
          Kwarg(name: "subdir", opt: true, types: [Str()]),
        ]
      ), Method(name: "language_version", parent: t, returnTypes: [Str()], args: []),
      Method(
        name: "get_path",
        parent: t,
        returnTypes: [Str()],
        args: [
          PositionalArgument(name: "path_name", types: [Str()]),
          PositionalArgument(name: "fallback", opt: true, types: [`Any`()]),
        ]
      ),
      Method(
        name: "has_path",
        parent: t,
        returnTypes: [BoolType()],
        args: [PositionalArgument(name: "path_name", types: [Str()])]
      ),
      Method(
        name: "get_variable",
        parent: t,
        returnTypes: [`Any`()],
        args: [
          PositionalArgument(name: "variable_name", types: [Str()]),
          PositionalArgument(name: "fallback", opt: true, types: [`Any`()]),
        ]
      ),
      Method(
        name: "has_variable",
        parent: t,
        returnTypes: [BoolType()],
        args: [PositionalArgument(name: "variable_name", types: [Str()])]
      ),
    ]
    t = self.types["python3_module"]!
    self.vtables["python3_module"] = [
      Method(name: "find_python", parent: t, returnTypes: [ExternalProgram()], args: []),
      Method(
        name: "extension_module",
        parent: t,
        returnTypes: [BuildTgt()],
        args: [
          PositionalArgument(name: "target_name", types: [Str()]),
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "c_args", opt: true, types: [ListType(types: [Str()])]),
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
            name: "d_module_versions",
            opt: true,
            types: [ListType(types: [Str(), `IntType`()])]
          ), Kwarg(name: "d_unittest", opt: true, types: [BoolType()]),
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
            name: "link_whole",
            opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]
          ),
          Kwarg(
            name: "link_with",
            opt: true,
            types: [ListType(types: [Lib(), CustomTgt(), CustomIdx()])]
          ), Kwarg(name: "name_prefix", opt: true, types: [Str(), ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [Str(), ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: [BoolType()]),
          Kwarg(
            name: "objects",
            opt: true,
            types: [ListType(types: [ExtractedObj(), File(), Str()])]
          ), Kwarg(name: "override_options", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "rust_crate_type", opt: true, types: [Str()]),
          Kwarg(
            name: "sources",
            opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList(), StructuredSrc()]
          ),
          Kwarg(
            name: "vs_module_defs",
            opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx()]
          ), Kwarg(name: "win_subsystem", opt: true, types: [Str()]),
        ]
      ), Method(name: "language_version", parent: t, returnTypes: [Str()], args: []),
      Method(
        name: "sysconfig_path",
        parent: t,
        returnTypes: [Str()],
        args: [PositionalArgument(name: "path_name", types: [Str()])]
      ),
    ]
    t = self.types["qt4_module"]!
    self.vtables["qt4_module"] = [
      Method(
        name: "compile_resources",
        parent: t,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          Kwarg(name: "name", opt: true, types: [Str()]),
          Kwarg(
            name: "sources",
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "extra_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "method", opt: true, types: [Str()]),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "compile_ui",
        parent: t,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          Kwarg(
            name: "sources",
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "extra_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "method", opt: true, types: [Str()]),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "compile_moc",
        parent: t,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          Kwarg(
            name: "sources",
            opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ),
          Kwarg(
            name: "headers",
            opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "extra_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "method", opt: true, types: [Str()]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep(), Lib()])]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc(), Str()])]),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "preprocess",
        parent: t,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          PositionalArgument(name: "name", opt: true, types: [Str()]),
          Kwarg(name: "sources", opt: true, types: [ListType(types: [Str(), File()])]),
          Kwarg(name: "qresources", opt: true, types: [ListType(types: [Str(), File()])]),
          Kwarg(
            name: "ui_files",
            opt: true,
            types: [ListType(types: [Str(), File(), CustomTgt()])]
          ),
          Kwarg(
            name: "moc_sources",
            opt: true,
            types: [ListType(types: [Str(), File(), CustomTgt()])]
          ),
          Kwarg(
            name: "moc_headers",
            opt: true,
            types: [ListType(types: [Str(), File(), CustomTgt()])]
          ), Kwarg(name: "moc_extra_arguments", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "rcc_extra_arguments", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "uic_extra_arguments", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "method", opt: true, types: [Str()]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep(), Lib()])]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc(), Str()])]),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "compile_translations",
        parent: t,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          Kwarg(name: "build_by_default", opt: true, types: [BoolType()]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(
            name: "ts_files",
            opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "rcc_extra_arguments", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "method", opt: true, types: [Str()]),
          Kwarg(name: "qresource", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "has_tools",
        parent: t,
        returnTypes: [BoolType()],
        args: [
          Kwarg(name: "required", opt: true, types: [BoolType()]),
          Kwarg(name: "method", opt: true, types: [Str()]),
        ]
      ),
    ]
    t = self.types["qt5_module"]!
    self.vtables["qt5_module"] = [
      Method(
        name: "compile_resources",
        parent: t,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          Kwarg(name: "name", opt: true, types: [Str()]),
          Kwarg(
            name: "sources",
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "extra_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "method", opt: true, types: [Str()]),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "compile_ui",
        parent: t,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          Kwarg(
            name: "sources",
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "extra_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "method", opt: true, types: [Str()]),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "compile_moc",
        parent: t,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          Kwarg(
            name: "sources",
            opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ),
          Kwarg(
            name: "headers",
            opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "extra_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "method", opt: true, types: [Str()]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep(), Lib()])]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc(), Str()])]),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "preprocess",
        parent: t,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          PositionalArgument(name: "name", opt: true, types: [Str()]),
          Kwarg(name: "sources", opt: true, types: [ListType(types: [Str(), File()])]),
          Kwarg(name: "qresources", opt: true, types: [ListType(types: [Str(), File()])]),
          Kwarg(
            name: "ui_files",
            opt: true,
            types: [ListType(types: [Str(), File(), CustomTgt()])]
          ),
          Kwarg(
            name: "moc_sources",
            opt: true,
            types: [ListType(types: [Str(), File(), CustomTgt()])]
          ),
          Kwarg(
            name: "moc_headers",
            opt: true,
            types: [ListType(types: [Str(), File(), CustomTgt()])]
          ), Kwarg(name: "moc_extra_arguments", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "rcc_extra_arguments", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "uic_extra_arguments", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "method", opt: true, types: [Str()]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep(), Lib()])]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc(), Str()])]),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "compile_translations",
        parent: t,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          Kwarg(name: "build_by_default", opt: true, types: [BoolType()]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(
            name: "ts_files",
            opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "rcc_extra_arguments", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "method", opt: true, types: [Str()]),
          Kwarg(name: "qresource", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "has_tools",
        parent: t,
        returnTypes: [BoolType()],
        args: [
          Kwarg(name: "required", opt: true, types: [BoolType()]),
          Kwarg(name: "method", opt: true, types: [Str()]),
        ]
      ),
    ]
    t = self.types["qt6_module"]!
    self.vtables["qt6_module"] = [
      Method(
        name: "compile_resources",
        parent: t,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          Kwarg(name: "name", opt: true, types: [Str()]),
          Kwarg(
            name: "sources",
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "extra_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "method", opt: true, types: [Str()]),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "compile_ui",
        parent: t,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          Kwarg(
            name: "sources",
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "extra_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "method", opt: true, types: [Str()]),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "compile_moc",
        parent: t,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          Kwarg(
            name: "sources",
            opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ),
          Kwarg(
            name: "headers",
            opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "extra_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "method", opt: true, types: [Str()]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep(), Lib()])]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc(), Str()])]),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "preprocess",
        parent: t,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          PositionalArgument(name: "name", opt: true, types: [Str()]),
          Kwarg(name: "sources", opt: true, types: [ListType(types: [Str(), File()])]),
          Kwarg(name: "qresources", opt: true, types: [ListType(types: [Str(), File()])]),
          Kwarg(
            name: "ui_files",
            opt: true,
            types: [ListType(types: [Str(), File(), CustomTgt()])]
          ),
          Kwarg(
            name: "moc_sources",
            opt: true,
            types: [ListType(types: [Str(), File(), CustomTgt()])]
          ),
          Kwarg(
            name: "moc_headers",
            opt: true,
            types: [ListType(types: [Str(), File(), CustomTgt()])]
          ), Kwarg(name: "moc_extra_arguments", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "rcc_extra_arguments", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "uic_extra_arguments", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "method", opt: true, types: [Str()]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep(), Lib()])]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc(), Str()])]),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "compile_translations",
        parent: t,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          Kwarg(name: "build_by_default", opt: true, types: [BoolType()]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(
            name: "ts_files",
            opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]
          ), Kwarg(name: "rcc_extra_arguments", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "method", opt: true, types: [Str()]),
          Kwarg(name: "qresource", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "has_tools",
        parent: t,
        returnTypes: [BoolType()],
        args: [
          Kwarg(name: "required", opt: true, types: [BoolType()]),
          Kwarg(name: "method", opt: true, types: [Str()]),
        ]
      ),
    ]
    t = self.types["rust_module"]!
    self.vtables["rust_module"] = [
      Method(
        name: "test",
        parent: t,
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
        parent: t,
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
    t = self.types["simd_module"]!
    self.vtables["simd_module"] = [
      Method(
        name: "check",
        parent: t,
        returnTypes: [ListType(types: [CfgData(), Lib()])],
        args: [
          PositionalArgument(name: "name", types: [Str()]),
          Kwarg(name: "compiler", opt: true, types: [Compiler()]),
          Kwarg(name: "mmx", opt: true, types: [Str(), File(), ListType(types: [Str(), File()])]),
          Kwarg(name: "sse", opt: true, types: [Str(), File(), ListType(types: [Str(), File()])]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Str(), Inc()])]),
          Kwarg(
            name: "sse2",
            opt: true,
            types: [Str(), File(), ListType(types: [Str(), File()])]
          ),
          Kwarg(
            name: "sse3",
            opt: true,
            types: [Str(), File(), ListType(types: [Str(), File()])]
          ),
          Kwarg(
            name: "ssse3",
            opt: true,
            types: [Str(), File(), ListType(types: [Str(), File()])]
          ),
          Kwarg(
            name: "sse41",
            opt: true,
            types: [Str(), File(), ListType(types: [Str(), File()])]
          ),
          Kwarg(
            name: "sse42",
            opt: true,
            types: [Str(), File(), ListType(types: [Str(), File()])]
          ),
          Kwarg(name: "avx", opt: true, types: [Str(), File(), ListType(types: [Str(), File()])]),
          Kwarg(
            name: "avx2",
            opt: true,
            types: [Str(), File(), ListType(types: [Str(), File()])]
          ),
          Kwarg(
            name: "neon",
            opt: true,
            types: [Str(), File(), ListType(types: [Str(), File()])]
          ),
        ]
      )
    ]
    t = self.types["sourcefiles"]!
    self.vtables["sourcefiles"] = [
      Method(
        name: "sources",
        parent: t,
        returnTypes: [ListType(types: [Str(), File()])],
        args: []
      ),
      Method(
        name: "dependencies",
        parent: t,
        returnTypes: [ListType(types: [Str(), File()])],
        args: []
      ),
    ]
    t = self.types["sourceset"]!
    self.vtables["sourceset"] = [
      Method(
        name: "add",
        parent: t,
        returnTypes: [],
        args: [
          PositionalArgument(
            name: "sources",
            varargs: true,
            opt: true,
            types: [Str(), File(), GeneratedList(), CustomTgt(), CustomIdx()]
          ), Kwarg(name: "when", opt: true, types: [ListType(types: [Dep()])]),
          Kwarg(
            name: "if_true",
            opt: true,
            types: [
              ListType(types: [Str(), File(), GeneratedList(), CustomTgt(), CustomIdx(), Dep()])
            ]
          ),
          Kwarg(
            name: "if_false",
            opt: true,
            types: [
              ListType(types: [Str(), File(), GeneratedList(), CustomTgt(), CustomIdx(), Dep()])
            ]
          ),
        ]
      ),
      Method(
        name: "add_all",
        parent: t,
        returnTypes: [],
        args: [
          PositionalArgument(name: "sources", varargs: true, opt: true, types: [t]),
          Kwarg(name: "when", opt: true, types: [ListType(types: [Dep()])]),
          Kwarg(name: "if_true", opt: true, types: [ListType(types: [t])]),
        ]
      ),
      Method(
        name: "all_sources",
        parent: t,
        returnTypes: [ListType(types: [Str(), File()])],
        args: []
      ),
      Method(
        name: "all_dependencies",
        parent: t,
        returnTypes: [ListType(types: [Str(), File()])],
        args: []
      ),
      Method(
        name: "apply",
        parent: t,
        returnTypes: [SourceFiles()],
        args: [
          PositionalArgument(name: "cfg", types: [CfgData(), Dict(types: [Str()])]),
          Kwarg(name: "strict", opt: true, types: [BoolType()]),
        ]
      ),
    ]
    t = self.types["sourceset_module"]!
    self.vtables["sourceset_module"] = [
      Method(name: "source_set", parent: t, returnTypes: [SourceSet()], args: [])
    ]
    t = self.types["wayland_module"]!
    self.vtables["wayland_module"] = [
      Method(
        name: "scan_xml",
        parent: t,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          PositionalArgument(name: "files", varargs: true, types: [Str(), File()]),
          Kwarg(name: "public", opt: true, types: [BoolType()]),
          Kwarg(name: "client", opt: true, types: [BoolType()]),
          Kwarg(name: "server", opt: true, types: [BoolType()]),
          Kwarg(name: "include_core_only", opt: true, types: [BoolType()]),
        ]
      ),
      Method(
        name: "find_protocol",
        parent: t,
        returnTypes: [File()],
        args: [
          PositionalArgument(name: "files", types: [Str()]),
          Kwarg(name: "state", opt: true, types: [Str()]),
          Kwarg(name: "version", opt: true, types: [`IntType`()]),
        ]
      ),
    ]
    t = self.types["windows_module"]!
    self.vtables["windows_module"] = [
      Method(
        name: "compile_resources",
        parent: t,
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

  public func lookupFunction(name: String) -> Function? {
    for f in self.functions where f.name == name { return f }
    return nil
  }

  public func lookupMethod(name: String) -> Method? {
    // TODO: Check what arguments/kwargs are given
    for o in self.types {
      if let obj = o.value as? AbstractObject, obj.parent != nil { continue }
      for m in self.vtables[o.value.name]! where m.name == name { return m }
    }
    for o in self.types {
      if o.value as? AbstractObject == nil { continue }
      if let obj = o.value as? AbstractObject, obj.parent == nil { continue }
      for m in self.vtables[o.value.name]! where m.name == name { return m }
    }
    return nil
  }
}
