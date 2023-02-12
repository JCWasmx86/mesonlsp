public class TypeNamespace {
  public var functions: [Function] = []
  public var types: [String: Type]

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
  }

  public func lookupFunction(name: String) -> Function? {
    for f in self.functions where f.name == name { return f }
    return nil
  }

  public func lookupMethod(name: String) -> Method? {
    // TODO: Check what arguments/kwargs are given
    for o in self.types {
      if let obj = o.value as? AbstractObject, obj.parent != nil { continue }
      for m in o.value.methods where m.name == name { return m }
    }
    for o in self.types {
      if o.value as? AbstractObject == nil { continue }
      if let obj = o.value as? AbstractObject, obj.parent == nil { continue }
      for m in o.value.methods where m.name == name { return m }
    }
    return nil
  }
}
