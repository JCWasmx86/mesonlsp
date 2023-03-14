public final class TypeNamespace {
  public let functions: [Function]
  public let types: [String: Type]
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
    let strL = [str]
    let strlist = ListType(types: strL)
    let strlistL = [strlist]
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
          PositionalArgument(
            name: "dependency",
            varargs: true,
            opt: true,
            types: [self.types["dep"]!]
          ), Kwarg(name: "language", types: strlistL),
          Kwarg(name: "native", opt: true, types: boolL),
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
          Kwarg(
            name: "env",
            opt: true,
            types: [self.types["env"]!, ListType(types: strL), Dict(types: strL)]
          ), Kwarg(name: "exclude_suites", opt: true, types: strlistL),
          Kwarg(
            name: "exe_wrapper",
            opt: true,
            types: [ListType(types: [str, self.types["external_program"]!])]
          ), Kwarg(name: "gdb", opt: true, types: boolL),
          Kwarg(name: "is_default", opt: true, types: boolL),
          Kwarg(name: "timeout_multiplier", opt: true, types: inttL),
        ]
      ),
      Function(
        name: "alias_target",
        returnTypes: [self.types["alias_tgt"]!],
        args: [
          PositionalArgument(name: "target_name", types: strL),
          PositionalArgument(name: "dep", varargs: true, opt: false, types: [self.types["dep"]!]),
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
          PositionalArgument(
            name: "executable",
            types: [
              self.types["exe"]!, self.types["jar"]!, self.types["external_program"]!,
              self.types["file"]!,
            ]
          ),
          Kwarg(
            name: "args",
            opt: true,
            types: [ListType(types: [str, self.types["file"]!, self.types["tgt"]!])]
          ),
          Kwarg(
            name: "depends",
            opt: true,
            types: [ListType(types: [self.types["build_tgt"]!, self.types["custom_tgt"]!])]
          ), Kwarg(name: "env", opt: true, types: [str, ListType(types: strL), Dict(types: strL)]),
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
        returnTypes: [self.types["both_libs"]!],
        args: [
          PositionalArgument(name: "target_name", types: strL),
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
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
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [self.types["dep"]!])]),
          Kwarg(
            name: "extra_files",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "gnu_symbol_visibility", opt: true, types: strL),
          Kwarg(name: "gui_app", opt: true, types: boolL),
          Kwarg(name: "implicit_include_directories", opt: true, types: boolL),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [str, self.types["inc"]!])]
          ), Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "install_rpath", opt: true, types: strL),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "link_args", opt: true, types: strlistL),
          Kwarg(
            name: "link_depends",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "link_language", opt: true, types: strL),
          Kwarg(
            name: "link_whole",
            opt: true,
            types: [
              ListType(types: [
                self.types["lib"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              ])
            ]
          ),
          Kwarg(
            name: "link_with",
            opt: true,
            types: [
              ListType(types: [
                self.types["lib"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              ])
            ]
          ), Kwarg(name: "name_prefix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(
            name: "objects",
            opt: true,
            types: [ListType(types: [self.types["extracted_obj"]!, self.types["file"]!, str])]
          ), Kwarg(name: "override_options", opt: true, types: strlistL),
          Kwarg(name: "pic", opt: true, types: boolL),
          Kwarg(name: "prelink", opt: true, types: boolL),
          Kwarg(name: "rust_crate_type", opt: true, types: strL),
          Kwarg(
            name: "sources",
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!, self.types["structured_src"]!,
            ]
          ), Kwarg(name: "soversion", opt: true, types: sil),
          Kwarg(name: "version", opt: true, types: strL),
          Kwarg(
            name: "vs_module_defs",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "win_subsystem", opt: true, types: strL),
        ]
      ),
      Function(
        name: "build_target",
        returnTypes: [self.types["build_tgt"]!],
        args: [
          PositionalArgument(name: "target_name", types: strL),
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
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
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [self.types["dep"]!])]),
          Kwarg(
            name: "extra_files",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "gnu_symbol_visibility", opt: true, types: strL),
          Kwarg(name: "gui_app", opt: true, types: boolL),
          Kwarg(name: "implib", opt: true, types: [boolt, str]),
          Kwarg(name: "implicit_include_directories", opt: true, types: boolL),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [str, self.types["inc"]!])]
          ), Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "install_rpath", opt: true, types: strL),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "java_resources", opt: true, types: [self.types["structured_src"]!]),
          Kwarg(name: "link_args", opt: true, types: strlistL),
          Kwarg(
            name: "link_depends",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "link_language", opt: true, types: strL),
          Kwarg(
            name: "link_whole",
            opt: true,
            types: [
              ListType(types: [
                self.types["lib"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              ])
            ]
          ),
          Kwarg(
            name: "link_with",
            opt: true,
            types: [
              ListType(types: [
                self.types["lib"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              ])
            ]
          ), Kwarg(name: "main_class", opt: true, types: strL),
          Kwarg(name: "name_prefix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(
            name: "objects",
            opt: true,
            types: [ListType(types: [self.types["extracted_obj"]!, self.types["file"]!, str])]
          ), Kwarg(name: "override_options", opt: true, types: strlistL),
          Kwarg(name: "pic", opt: true, types: boolL), Kwarg(name: "pie", opt: true, types: boolL),
          Kwarg(name: "prelink", opt: true, types: boolL),
          Kwarg(name: "rust_crate_type", opt: true, types: strL),
          Kwarg(
            name: "sources",
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!, self.types["structured_src"]!,
            ]
          ), Kwarg(name: "soversion", opt: true, types: sil),
          Kwarg(name: "version", opt: true, types: strL), Kwarg(name: "target_type", types: strL),
          Kwarg(
            name: "vs_module_defs",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "win_subsystem", opt: true, types: strL),
        ]
      ),
      Function(
        name: "configuration_data",
        returnTypes: [self.types["cfg_data"]!],
        args: [
          PositionalArgument(name: "data", opt: true, types: [Dict(types: [str, boolt, intt])])
        ]
      ),
      Function(
        name: "configure_file",
        returnTypes: [self.types["file"]!],
        args: [
          Kwarg(name: "capture", opt: true, types: boolL),
          Kwarg(name: "command", opt: true, types: [ListType(types: [str, self.types["file"]!])]),
          Kwarg(
            name: "configuration",
            opt: true,
            types: [Dict(types: silb), self.types["cfg_data"]!]
          ), Kwarg(name: "copy", opt: true, types: boolL),
          Kwarg(name: "depfile", opt: true, types: strL),
          Kwarg(name: "encoding", opt: true, types: strL),
          Kwarg(name: "format", opt: true, types: strL),
          Kwarg(name: "input", opt: true, types: [str, self.types["file"]!]),
          Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "install_tag", opt: true, types: strL), Kwarg(name: "output", types: strL),
          Kwarg(name: "output_format", opt: true, types: strL),
        ]
      ),
      Function(
        name: "custom_target",
        returnTypes: [self.types["custom_tgt"]!],
        args: [
          PositionalArgument(name: "name", opt: true, types: strL),
          Kwarg(name: "build_always", opt: true, types: boolL),
          Kwarg(name: "build_always_stale", opt: true, types: boolL),
          Kwarg(name: "build_by_default", opt: true, types: boolL),
          Kwarg(name: "capture", opt: true, types: boolL),
          Kwarg(
            name: "command",
            types: [
              ListType(types: [
                str, self.types["file"]!, self.types["exe"]!, self.types["external_program"]!,
              ])
            ]
          ), Kwarg(name: "console", opt: true, types: boolL),
          Kwarg(
            name: "depend_files",
            opt: true,
            types: [ListType(types: [str, self.types["file"]!])]
          ),
          Kwarg(
            name: "depends",
            opt: true,
            types: [ListType(types: [self.types["build_tgt"]!, self.types["custom_tgt"]!])]
          ), Kwarg(name: "depfile", opt: true, types: strL),
          Kwarg(
            name: "env",
            opt: true,
            types: [self.types["env"]!, ListType(types: strL), Dict(types: strL)]
          ), Kwarg(name: "feed", opt: true, types: boolL),
          Kwarg(name: "input", opt: true, types: [ListType(types: [str, self.types["file"]!])]),
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
            opt: true,
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
        returnTypes: [self.types["dep"]!],
        args: [
          Kwarg(name: "compile_args", opt: true, types: strlistL),
          Kwarg(
            name: "d_import_dirs",
            opt: true,
            types: [ListType(types: [str, self.types["inc"]!])]
          ), Kwarg(name: "d_module_versions", opt: true, types: [str, intt, ListType(types: sil)]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [self.types["dep"]!])]),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [str, self.types["inc"]!])]
          ), Kwarg(name: "link_args", opt: true, types: strlistL),
          Kwarg(name: "link_whole", opt: true, types: [ListType(types: [self.types["lib"]!])]),
          Kwarg(name: "link_with", opt: true, types: [ListType(types: [self.types["lib"]!])]),
          Kwarg(
            name: "objects",
            opt: true,
            types: [ListType(types: [self.types["extracted_obj"]!])]
          ),
          Kwarg(
            name: "sources",
            opt: true,
            types: [
              ListType(types: [
                str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
                self.types["generated_list"]!,
              ])
            ]
          ),
          Kwarg(name: "variables", opt: true, types: [ListType(types: strL), Dict(types: strL)]),
          Kwarg(name: "version", opt: true, types: strL),
        ]
      ),
      Function(
        name: "dependency",
        returnTypes: [self.types["dep"]!],
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
          Kwarg(name: "required", opt: true, types: [boolt, self.types["feature"]!]),
          Kwarg(name: "static", opt: true, types: boolL),
          Kwarg(name: "version", opt: true, types: strL),
          Kwarg(name: "cmake_package_version", opt: true, types: strL),
        ]
      ), Function(name: "disabler", returnTypes: [self.types["disabler"]!]),
      Function(
        name: "environment",
        returnTypes: [self.types["env"]!],
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
          PositionalArgument(name: "message", opt: true, types: strL),
          PositionalArgument(name: "msg", varargs: true, opt: true, types: strL),
        ]
      ),
      Function(
        name: "executable",
        returnTypes: [self.types["exe"]!],
        args: [
          PositionalArgument(name: "target_name", types: strL),
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
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
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [self.types["dep"]!])]),
          Kwarg(name: "export_dynamic", opt: true, types: boolL),
          Kwarg(
            name: "extra_files",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "gnu_symbol_visibility", opt: true, types: strL),
          Kwarg(name: "gui_app", opt: true, types: boolL),
          Kwarg(name: "implib", opt: true, types: [boolt, str]),
          Kwarg(name: "implicit_include_directories", opt: true, types: boolL),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [str, self.types["inc"]!])]
          ), Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "install_rpath", opt: true, types: strL),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "link_args", opt: true, types: strlistL),
          Kwarg(
            name: "link_depends",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "link_language", opt: true, types: strL),
          Kwarg(
            name: "link_whole",
            opt: true,
            types: [
              ListType(types: [
                self.types["lib"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              ])
            ]
          ),
          Kwarg(
            name: "link_with",
            opt: true,
            types: [
              ListType(types: [
                self.types["lib"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              ])
            ]
          ), Kwarg(name: "name_prefix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(
            name: "objects",
            opt: true,
            types: [ListType(types: [self.types["extracted_obj"]!, self.types["file"]!, str])]
          ), Kwarg(name: "override_options", opt: true, types: strlistL),
          Kwarg(name: "pie", opt: true, types: boolL),
          Kwarg(name: "rust_crate_type", opt: true, types: strL),
          Kwarg(
            name: "sources",
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!, self.types["structured_src"]!,
            ]
          ), Kwarg(name: "win_subsystem", opt: true, types: strL),
        ]
      ),
      Function(
        name: "files",
        returnTypes: [ListType(types: [self.types["file"]!])],
        args: [PositionalArgument(name: "file", varargs: true, opt: true, types: strL)]
      ),
      Function(
        name: "find_program",
        returnTypes: [self.types["external_program"]!],
        args: [
          PositionalArgument(name: "program_name", types: [str, self.types["file"]!]),
          PositionalArgument(
            name: "fallback",
            varargs: true,
            opt: true,
            types: [str, self.types["file"]!]
          ), Kwarg(name: "dirs", opt: true, types: strlistL),
          Kwarg(name: "disabler", opt: true, types: boolL),
          Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(name: "required", opt: true, types: [boolt, self.types["feature"]!]),
          Kwarg(name: "version", opt: true, types: strL),
        ]
      ),
      Function(
        name: "generator",
        returnTypes: [self.types["generator"]!],
        args: [
          PositionalArgument(
            name: "exe",
            types: [self.types["exe"]!, self.types["external_program"]!]
          ), Kwarg(name: "arguments", opt: true, types: strlistL),
          Kwarg(name: "capture", opt: true, types: boolL),
          Kwarg(
            name: "depends",
            opt: true,
            types: [ListType(types: [self.types["build_tgt"]!, self.types["custom_tgt"]!])]
          ), Kwarg(name: "depfile", opt: true, types: strL),
          Kwarg(name: "output", opt: true, types: strlistL),
        ]
      ),
      Function(
        name: "get_option",
        returnTypes: [str, intt, boolt, self.types["feature"]!, ListType(types: silb)],
        args: [PositionalArgument(name: "option_name", types: strL)]
      ),
      Function(
        name: "get_variable",
        returnTypes: [
          self.types["any"]!, ListType(types: [self.types["any"]!]),
          Dict(types: [self.types["any"]!]),
        ],
        args: [
          PositionalArgument(name: "variable_name", types: strL),
          PositionalArgument(name: "default", opt: true, types: [self.types["any"]!]),
        ]
      ),
      Function(
        name: "import",
        returnTypes: [self.types["module"]!],
        args: [
          PositionalArgument(name: "module_name", types: strL),
          Kwarg(name: "module_name", opt: true, types: boolL),
          Kwarg(name: "required", opt: true, types: [boolt, self.types["feature"]!]),
          Kwarg(name: "disabler", opt: true, types: boolL),
        ]
      ),
      Function(
        name: "include_directories",
        returnTypes: [self.types["inc"]!],
        args: [
          PositionalArgument(name: "includes", varargs: true, opt: true, types: strL),
          Kwarg(name: "is_system", opt: true, types: boolL),
        ]
      ),
      Function(
        name: "install_data",
        args: [
          PositionalArgument(
            name: "file",
            varargs: true,
            opt: true,
            types: [str, self.types["file"]!]
          ), Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "preserve_path", opt: true, types: boolL),
          Kwarg(name: "rename", opt: true, types: strlistL),
          Kwarg(name: "sources", opt: true, types: [ListType(types: [self.types["file"]!, str])]),
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
          PositionalArgument(
            name: "file",
            varargs: true,
            opt: true,
            types: [str, self.types["file"]!]
          ), Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "preserve_path", opt: true, types: boolL),
          Kwarg(name: "subdir", opt: true, types: strL),
        ]
      ),
      Function(
        name: "install_man",
        args: [
          PositionalArgument(
            name: "file",
            varargs: true,
            opt: true,
            types: [str, self.types["file"]!]
          ), Kwarg(name: "install_dir", opt: true, types: strL),
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
        args: [PositionalArgument(name: "var", types: [self.types["any"]!])]
      ),
      Function(
        name: "is_variable",
        returnTypes: boolL,
        args: [PositionalArgument(name: "var", types: boolL)]
      ),
      Function(
        name: "jar",
        returnTypes: [self.types["jar"]!],
        args: [
          PositionalArgument(name: "target_name", types: strL),
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
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
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [self.types["dep"]!])]),
          Kwarg(
            name: "extra_files",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "gnu_symbol_visibility", opt: true, types: strL),
          Kwarg(name: "gui_app", opt: true, types: boolL),
          Kwarg(name: "implicit_include_directories", opt: true, types: boolL),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [str, self.types["inc"]!])]
          ), Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "install_rpath", opt: true, types: strL),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "java_resources", opt: true, types: [self.types["structured_src"]!]),
          Kwarg(name: "link_args", opt: true, types: strlistL),
          Kwarg(
            name: "link_depends",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "link_language", opt: true, types: strL),
          Kwarg(
            name: "link_whole",
            opt: true,
            types: [
              ListType(types: [
                self.types["lib"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              ])
            ]
          ),
          Kwarg(
            name: "link_with",
            opt: true,
            types: [
              ListType(types: [
                self.types["lib"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              ])
            ]
          ), Kwarg(name: "main_class", opt: true, types: strL),
          Kwarg(name: "name_prefix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(
            name: "objects",
            opt: true,
            types: [ListType(types: [self.types["extracted_obj"]!, self.types["file"]!, str])]
          ), Kwarg(name: "override_options", opt: true, types: strlistL),
          Kwarg(name: "rust_crate_type", opt: true, types: strL),
          Kwarg(
            name: "sources",
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!, self.types["structured_src"]!,
            ]
          ), Kwarg(name: "win_subsystem", opt: true, types: strL),
        ]
      ),
      Function(
        name: "join_paths",
        returnTypes: strL,
        args: [PositionalArgument(name: "part", varargs: true, opt: true, types: strL)]
      ),
      Function(
        name: "library",
        returnTypes: [self.types["lib"]!, self.types["both_libs"]!],
        args: [
          PositionalArgument(name: "target_name", types: strL),
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
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
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [self.types["dep"]!])]),
          Kwarg(
            name: "extra_files",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "gnu_symbol_visibility", opt: true, types: strL),
          Kwarg(name: "gui_app", opt: true, types: boolL),
          Kwarg(name: "implicit_include_directories", opt: true, types: boolL),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [str, self.types["inc"]!])]
          ), Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "install_rpath", opt: true, types: strL),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "link_args", opt: true, types: strlistL),
          Kwarg(
            name: "link_depends",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "link_language", opt: true, types: strL),
          Kwarg(
            name: "link_whole",
            opt: true,
            types: [
              ListType(types: [
                self.types["lib"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              ])
            ]
          ),
          Kwarg(
            name: "link_with",
            opt: true,
            types: [
              ListType(types: [
                self.types["lib"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              ])
            ]
          ), Kwarg(name: "name_prefix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(
            name: "objects",
            opt: true,
            types: [ListType(types: [self.types["extracted_obj"]!, self.types["file"]!, str])]
          ), Kwarg(name: "override_options", opt: true, types: strlistL),
          Kwarg(name: "pic", opt: true, types: boolL),
          Kwarg(name: "prelink", opt: true, types: boolL),
          Kwarg(name: "rust_crate_type", opt: true, types: strL),
          Kwarg(
            name: "sources",
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!, self.types["structured_src"]!,
            ]
          ), Kwarg(name: "soversion", opt: true, types: sil),
          Kwarg(name: "version", opt: true, types: strL),
          Kwarg(
            name: "vs_module_defs",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "win_subsystem", opt: true, types: strL),
        ]
      ),
      Function(
        name: "message",
        args: [
          PositionalArgument(
            name: "message",
            opt: true,
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
          Kwarg(name: "version", opt: true, types: [str, self.types["file"]!]),
        ]
      ),
      Function(
        name: "range",
        returnTypes: [self.types["range"]!],
        args: [
          PositionalArgument(name: "start", opt: true, types: inttL),
          PositionalArgument(name: "stop", opt: true, types: inttL),
          PositionalArgument(name: "step", opt: true, types: inttL),
        ]
      ),
      Function(
        name: "run_command",
        returnTypes: [self.types["runresult"]!],
        args: [
          PositionalArgument(
            name: "command",
            varargs: true,
            opt: true,
            types: [str, self.types["file"]!, self.types["external_program"]!]
          ), Kwarg(name: "capture", opt: true, types: boolL),
          Kwarg(name: "check", opt: true, types: boolL),
          Kwarg(
            name: "env",
            opt: true,
            types: [self.types["env"]!, ListType(types: strL), Dict(types: strL)]
          ),
        ]
      ),
      Function(
        name: "run_target",
        returnTypes: [self.types["run_tgt"]!],
        args: [
          PositionalArgument(name: "target_name", types: strL),
          Kwarg(
            name: "command",
            types: [
              ListType(types: [
                self.types["exe"]!, self.types["external_program"]!, self.types["custom_tgt"]!,
                self.types["file"]!, str,
              ])
            ]
          ),
          Kwarg(
            name: "depends",
            opt: true,
            types: [ListType(types: [self.types["custom_tgt"]!, self.types["build_tgt"]!])]
          ),
          Kwarg(
            name: "env",
            opt: true,
            types: [self.types["env"]!, ListType(types: strL), Dict(types: strL)]
          ),
        ]
      ),
      Function(
        name: "set_variable",
        args: [
          PositionalArgument(name: "variable_name", types: strL),
          PositionalArgument(name: "value", types: [self.types["any"]!]),
        ]
      ),
      Function(
        name: "shared_library",
        returnTypes: [self.types["lib"]!],
        args: [
          PositionalArgument(name: "target_name", types: strL),
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
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
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [self.types["dep"]!])]),
          Kwarg(
            name: "extra_files",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "gnu_symbol_visibility", opt: true, types: strL),
          Kwarg(name: "gui_app", opt: true, types: boolL),
          Kwarg(name: "implicit_include_directories", opt: true, types: boolL),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [str, self.types["inc"]!])]
          ), Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "install_rpath", opt: true, types: strL),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "link_args", opt: true, types: strlistL),
          Kwarg(
            name: "link_depends",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "link_language", opt: true, types: strL),
          Kwarg(
            name: "link_whole",
            opt: true,
            types: [
              ListType(types: [
                self.types["lib"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              ])
            ]
          ),
          Kwarg(
            name: "link_with",
            opt: true,
            types: [
              ListType(types: [
                self.types["lib"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              ])
            ]
          ), Kwarg(name: "name_prefix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(
            name: "objects",
            opt: true,
            types: [ListType(types: [self.types["extracted_obj"]!, self.types["file"]!, str])]
          ), Kwarg(name: "override_options", opt: true, types: strlistL),
          Kwarg(name: "rust_crate_type", opt: true, types: strL),
          Kwarg(
            name: "sources",
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!, self.types["structured_src"]!,
            ]
          ), Kwarg(name: "soversion", opt: true, types: sil),
          Kwarg(name: "version", opt: true, types: strL),
          Kwarg(
            name: "vs_module_defs",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "win_subsystem", opt: true, types: strL),
        ]
      ),
      Function(
        name: "shared_module",
        returnTypes: [self.types["build_tgt"]!],
        args: [
          PositionalArgument(name: "target_name", types: strL),
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
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
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [self.types["dep"]!])]),
          Kwarg(
            name: "extra_files",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "gnu_symbol_visibility", opt: true, types: strL),
          Kwarg(name: "gui_app", opt: true, types: boolL),
          Kwarg(name: "implicit_include_directories", opt: true, types: boolL),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [str, self.types["inc"]!])]
          ), Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "install_rpath", opt: true, types: strL),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "link_args", opt: true, types: strlistL),
          Kwarg(
            name: "link_depends",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "link_language", opt: true, types: strL),
          Kwarg(
            name: "link_whole",
            opt: true,
            types: [
              ListType(types: [
                self.types["lib"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              ])
            ]
          ),
          Kwarg(
            name: "link_with",
            opt: true,
            types: [
              ListType(types: [
                self.types["lib"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              ])
            ]
          ), Kwarg(name: "name_prefix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(
            name: "objects",
            opt: true,
            types: [ListType(types: [self.types["extracted_obj"]!, self.types["file"]!, str])]
          ), Kwarg(name: "override_options", opt: true, types: strlistL),
          Kwarg(name: "rust_crate_type", opt: true, types: strL),
          Kwarg(
            name: "sources",
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!, self.types["structured_src"]!,
            ]
          ),
          Kwarg(
            name: "vs_module_defs",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "win_subsystem", opt: true, types: strL),
        ]
      ),
      Function(
        name: "static_library",
        returnTypes: [self.types["lib"]!],
        args: [
          PositionalArgument(name: "target_name", types: strL),
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
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
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [self.types["dep"]!])]),
          Kwarg(
            name: "extra_files",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "gnu_symbol_visibility", opt: true, types: strL),
          Kwarg(name: "gui_app", opt: true, types: boolL),
          Kwarg(name: "implicit_include_directories", opt: true, types: boolL),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [str, self.types["inc"]!])]
          ), Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: sil)]),
          Kwarg(name: "install_rpath", opt: true, types: strL),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "link_args", opt: true, types: strlistL),
          Kwarg(
            name: "link_depends",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "link_language", opt: true, types: strL),
          Kwarg(
            name: "link_whole",
            opt: true,
            types: [
              ListType(types: [
                self.types["lib"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              ])
            ]
          ),
          Kwarg(
            name: "link_with",
            opt: true,
            types: [
              ListType(types: [
                self.types["lib"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              ])
            ]
          ), Kwarg(name: "name_prefix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(
            name: "objects",
            opt: true,
            types: [ListType(types: [self.types["extracted_obj"]!, self.types["file"]!, str])]
          ), Kwarg(name: "override_options", opt: true, types: strlistL),
          Kwarg(name: "pic", opt: true, types: boolL),
          Kwarg(name: "prelink", opt: true, types: boolL),
          Kwarg(name: "rust_crate_type", opt: true, types: strL),
          Kwarg(
            name: "sources",
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!, self.types["structured_src"]!,
            ]
          ), Kwarg(name: "soversion", opt: true, types: sil),
          Kwarg(name: "version", opt: true, types: strL),
          Kwarg(
            name: "vs_module_defs",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "win_subsystem", opt: true, types: strL),
        ]
      ),
      Function(
        name: "structured_sources",
        returnTypes: [self.types["structured_src"]!],
        args: [
          PositionalArgument(
            name: "root",
            types: [
              ListType(types: [
                str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
                self.types["generated_list"]!,
              ])
            ]
          ),
          PositionalArgument(
            name: "additional",
            opt: true,
            types: [
              Dict(types: [
                str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
                self.types["generated_list"]!,
              ])
            ]
          ),
        ]
      ),
      Function(
        name: "subdir",
        args: [
          PositionalArgument(name: "dir_name", types: strL),
          Kwarg(name: "if_found", opt: true, types: [ListType(types: [self.types["dep"]!])]),
        ]
      ), Function(name: "subdir_done"),
      Function(
        name: "subproject",
        returnTypes: [self.types["subproject"]!],
        args: [
          PositionalArgument(name: "subproject_name", types: strL),
          Kwarg(name: "default_options", opt: true, types: strlistL),
          Kwarg(name: "required", opt: true, types: [boolt, self.types["feature"]!]),
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
                str, boolt, intt, self.types["dep"]!, self.types["external_program"]!,
                ListType(types: [
                  str, boolt, intt, self.types["dep"]!, self.types["external_program"]!,
                ]),
              ]),
            ]
          ),
          PositionalArgument(
            name: "value",
            opt: true,
            types: [
              str, boolt, intt, self.types["dep"]!, self.types["external_program"]!,
              ListType(types: [
                str, boolt, intt, self.types["dep"]!, self.types["external_program"]!,
              ]),
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
          PositionalArgument(
            name: "executable",
            types: [
              self.types["exe"]!, self.types["jar"]!, self.types["external_program"]!,
              self.types["file"]!,
            ]
          ),
          Kwarg(
            name: "args",
            opt: true,
            types: [ListType(types: [str, self.types["file"]!, self.types["tgt"]!])]
          ),
          Kwarg(
            name: "depends",
            opt: true,
            types: [ListType(types: [self.types["build_tgt"]!, self.types["custom_tgt"]!])]
          ), Kwarg(name: "env", opt: true, types: [str, ListType(types: strL), Dict(types: strL)]),
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
        returnTypes: [self.types["custom_tgt"]!],
        args: [
          Kwarg(
            name: "command",
            opt: true,
            types: [
              ListType(types: [
                self.types["exe"]!, self.types["external_program"]!, self.types["custom_tgt"]!,
                self.types["file"]!, str,
              ])
            ]
          ), Kwarg(name: "fallback", opt: true, types: strL), Kwarg(name: "input", types: strL),
          Kwarg(name: "output", types: strL), Kwarg(name: "replace_string", opt: true, types: strL),
        ]
      ),
      Function(
        name: "warning",
        args: [
          PositionalArgument(
            name: "message",
            opt: true,
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
    var t = self.types["any"]!
    self.vtables["any"] = []
    t = boolt
    self.vtables["bool"] = [
      Method(name: "to_int", parent: t, returnTypes: inttL),
      Method(
        name: "to_string",
        parent: t,
        returnTypes: strL,
        args: [
          PositionalArgument(name: "true_str", opt: true, types: strL),
          PositionalArgument(name: "false_str", opt: true, types: strL),
        ]
      ),
    ]
    t = self.types["build_machine"]!
    self.vtables["build_machine"] = [
      Method(name: "cpu", parent: t, returnTypes: strL),
      Method(name: "cpu_family", parent: t, returnTypes: strL),
      Method(name: "endian", parent: t, returnTypes: strL),
      Method(name: "system", parent: t, returnTypes: strL),
    ]
    t = self.types["dict"]!
    self.vtables["dict"] = [
      Method(
        name: "get",
        parent: t,
        returnTypes: [self.types["any"]!],
        args: [
          PositionalArgument(name: "key", types: strL),
          PositionalArgument(name: "fallback", opt: true, types: [self.types["any"]!]),
        ]
      ),
      Method(
        name: "has_key",
        parent: t,
        returnTypes: boolL,
        args: [PositionalArgument(name: "key", types: strL)]
      ), Method(name: "keys", parent: t, returnTypes: [ListType(types: strL)]),
    ]
    t = self.types["host_machine"]!
    self.vtables["host_machine"] = []
    t = intt
    self.vtables["int"] = [
      Method(name: "is_even", parent: t, returnTypes: boolL),
      Method(name: "is_odd", parent: t, returnTypes: boolL),
      Method(name: "to_string", parent: t, returnTypes: strL),
    ]
    t = self.types["list"]!
    self.vtables["list"] = [
      Method(
        name: "contains",
        parent: t,
        returnTypes: boolL,
        args: [PositionalArgument(name: "item", types: [self.types["any"]!])]
      ),
      Method(
        name: "get",
        parent: t,
        returnTypes: [self.types["any"]!],
        args: [
          PositionalArgument(name: "index", types: inttL),
          PositionalArgument(name: "fallback", opt: true, types: [self.types["any"]!]),
        ]
      ), Method(name: "length", parent: t, returnTypes: inttL),
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
              self.types["env"]!, str, ListType(types: strL), Dict(types: strL),
              Dict(types: [ListType(types: strL)]),
            ]
          ), Kwarg(name: "method", opt: true, types: strL),
          Kwarg(name: "separator", opt: true, types: strL),
        ]
      ),
      Method(
        name: "add_dist_script",
        parent: t,
        args: [
          PositionalArgument(
            name: "script_name",
            types: [str, self.types["file"]!, self.types["external_program"]!]
          ),
          PositionalArgument(
            name: "arg",
            varargs: true,
            opt: true,
            types: [str, self.types["file"]!, self.types["external_program"]!]
          ),
        ]
      ),
      Method(
        name: "add_install_script",
        parent: t,
        args: [
          PositionalArgument(
            name: "script_name",
            types: [
              str, self.types["file"]!, self.types["external_program"]!, self.types["exe"]!,
              self.types["custom_tgt"]!, self.types["custom_idx"]!,
            ]
          ),
          PositionalArgument(
            name: "arg",
            varargs: true,
            opt: true,
            types: [
              str, self.types["file"]!, self.types["external_program"]!, self.types["exe"]!,
              self.types["custom_tgt"]!, self.types["custom_idx"]!,
            ]
          ), Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "skip_if_destdir", opt: true, types: boolL),
        ]
      ),
      Method(
        name: "add_postconf_script",
        parent: t,
        args: [
          PositionalArgument(
            name: "script_name",
            types: [str, self.types["file"]!, self.types["external_program"]!]
          ),
          PositionalArgument(
            name: "arg",
            varargs: true,
            opt: true,
            types: [str, self.types["file"]!, self.types["external_program"]!]
          ),
        ]
      ), Method(name: "backend", parent: t, returnTypes: strL),
      Method(name: "build_root", parent: t, returnTypes: strL),
      Method(name: "can_run_host_binaries", parent: t, returnTypes: boolL),
      Method(name: "current_build_dir", parent: t, returnTypes: strL),
      Method(name: "current_source_dir", parent: t, returnTypes: strL),
      Method(
        name: "get_compiler",
        parent: t,
        returnTypes: [self.types["compiler"]!],
        args: [
          PositionalArgument(name: "language", types: strL),
          Kwarg(name: "native", opt: true, types: boolL),
        ]
      ),
      Method(
        name: "get_cross_property",
        parent: t,
        returnTypes: [
          self.types["any"]!, ListType(types: [self.types["any"]!]),
          Dict(types: [self.types["any"]!]),
        ],
        args: [
          PositionalArgument(name: "propname", types: strL),
          PositionalArgument(name: "fallback_value", opt: true, types: [self.types["any"]!]),
        ]
      ),
      Method(
        name: "get_external_property",
        parent: t,
        returnTypes: [
          self.types["any"]!, ListType(types: [self.types["any"]!]),
          Dict(types: [self.types["any"]!]),
        ],
        args: [
          PositionalArgument(name: "propname", types: strL),
          PositionalArgument(name: "fallback_value", opt: true, types: [self.types["any"]!]),
          Kwarg(name: "native", opt: true, types: boolL),
        ]
      ), Method(name: "global_build_root", parent: t, returnTypes: strL),
      Method(name: "global_source_root", parent: t, returnTypes: strL),
      Method(name: "has_exe_wrapper", parent: t, returnTypes: boolL),
      Method(
        name: "has_external_property",
        parent: t,
        returnTypes: boolL,
        args: [
          PositionalArgument(name: "propname", types: strL),
          Kwarg(name: "native", opt: true, types: boolL),
        ]
      ),
      Method(
        name: "install_dependency_manifest",
        parent: t,
        args: [PositionalArgument(name: "output_name", types: strL)]
      ), Method(name: "is_cross_build", parent: t, returnTypes: boolL),
      Method(name: "is_subproject", parent: t, returnTypes: boolL),
      Method(name: "is_unity", parent: t, returnTypes: boolL),
      Method(
        name: "override_dependency",
        parent: t,
        args: [
          PositionalArgument(name: "name", types: strL),
          PositionalArgument(name: "dep_object", types: [self.types["dep"]!]),
          Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(name: "static", opt: true, types: boolL),
        ]
      ),
      Method(
        name: "override_find_program",
        parent: t,
        args: [
          PositionalArgument(name: "progname", types: strL),
          PositionalArgument(
            name: "program",
            types: [self.types["exe"]!, self.types["file"]!, self.types["external_program"]!]
          ),
        ]
      ), Method(name: "project_build_root", parent: t, returnTypes: strL),
      Method(name: "project_license", parent: t, returnTypes: [ListType(types: strL)]),
      Method(name: "project_license_files", parent: t),
      Method(name: "project_name", parent: t, returnTypes: strL),
      Method(name: "project_source_root", parent: t, returnTypes: strL),
      Method(name: "project_version", parent: t, returnTypes: strL),
      Method(name: "source_root", parent: t, returnTypes: strL),
      Method(name: "version", parent: t, returnTypes: strL),
    ]
    t = str
    self.vtables["str"] = [
      Method(
        name: "contains",
        parent: t,
        returnTypes: boolL,
        args: [PositionalArgument(name: "fragment", types: [t])]
      ),
      Method(
        name: "endswith",
        parent: t,
        returnTypes: boolL,
        args: [PositionalArgument(name: "fragment", types: [t])]
      ),
      Method(
        name: "format",
        parent: t,
        returnTypes: [t],
        args: [
          PositionalArgument(name: "fmt", types: [t]),
          PositionalArgument(name: "value", varargs: true, opt: true, types: [intt, boolt, t]),
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
        returnTypes: boolL,
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
          PositionalArgument(name: "start", opt: true, types: inttL),
          PositionalArgument(name: "end", opt: true, types: inttL),
        ]
      ), Method(name: "to_int", parent: t, returnTypes: inttL),
      Method(name: "to_lower", parent: t, returnTypes: [t]),
      Method(name: "to_upper", parent: t, returnTypes: [t]),
      Method(name: "underscorify", parent: t, returnTypes: [t]),
      Method(
        name: "version_compare",
        parent: t,
        returnTypes: boolL,
        args: [PositionalArgument(name: "compare_string", types: [t])]
      ),
    ]
    t = self.types["target_machine"]!
    self.vtables["target_machine"] = []
    t = self.types["alias_tgt"]!
    self.vtables["alias_tgt"] = []
    t = self.types["both_libs"]!
    self.vtables["both_libs"] = [
      Method(name: "get_shared_lib", parent: t, returnTypes: [self.types["lib"]!]),
      Method(name: "get_static_lib", parent: t, returnTypes: [self.types["lib"]!]),
    ]
    t = self.types["build_tgt"]!
    self.vtables["build_tgt"] = [
      Method(
        name: "extract_all_objects",
        parent: t,
        returnTypes: [self.types["extracted_obj"]!],
        args: [Kwarg(name: "recursive", opt: true, types: [self.types["extracted_obj"]!])]
      ),
      Method(
        name: "extract_objects",
        parent: t,
        returnTypes: [self.types["extracted_obj"]!],
        args: [
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: true,
            types: [str, self.types["file"]!]
          )
        ]
      ), Method(name: "found", parent: t, returnTypes: boolL),
      Method(name: "full_path", parent: t, returnTypes: strL),
      // TODO: Is this an internal method?
      Method(name: "outdir", parent: t, returnTypes: strL),
      Method(name: "name", parent: t, returnTypes: strL),
      Method(name: "path", parent: t, returnTypes: strL),
      Method(name: "private_dir_include", parent: t, returnTypes: [self.types["inc"]!]),
    ]
    t = self.types["cfg_data"]!
    self.vtables["cfg_data"] = [
      Method(
        name: "get",
        parent: t,
        returnTypes: [boolt, str, intt],
        args: [
          PositionalArgument(name: "varname", types: strL),
          PositionalArgument(name: "default_value", opt: true, types: [str, intt, boolt]),
        ]
      ),
      Method(
        name: "get_unquoted",
        parent: t,
        returnTypes: [boolt, str, intt],
        args: [
          PositionalArgument(name: "varname", types: strL),
          PositionalArgument(name: "default_value", opt: true, types: [str, intt, boolt]),
        ]
      ),
      Method(
        name: "has",
        parent: t,
        returnTypes: boolL,
        args: [PositionalArgument(name: "varname", types: strL)]
      ), Method(name: "keys", parent: t, returnTypes: [ListType(types: strL)]),
      Method(name: "merge_from", parent: t, args: [PositionalArgument(name: "other", types: [t])]),
      Method(
        name: "set",
        parent: t,
        args: [
          PositionalArgument(name: "varname", types: strL),
          PositionalArgument(name: "value", types: [str, intt, boolt]),
          Kwarg(name: "description", opt: true, types: strL),
        ]
      ),
      Method(
        name: "set10",
        parent: t,
        args: [
          PositionalArgument(name: "varname", types: strL),
          PositionalArgument(name: "value", types: [str, intt, boolt]),
          Kwarg(name: "description", opt: true, types: strL),
        ]
      ),
      Method(
        name: "set_quoted",
        parent: t,
        args: [
          PositionalArgument(name: "varname", types: strL),
          PositionalArgument(name: "value", types: [str, intt, boolt]),
          Kwarg(name: "description", opt: true, types: strL),
        ]
      ),
    ]
    t = self.types["compiler"]!
    self.vtables["compiler"] = [
      Method(
        name: "alignment",
        parent: t,
        returnTypes: inttL,
        args: [
          PositionalArgument(name: "typename", types: strL),
          Kwarg(name: "args", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [self.types["dep"]!]), self.types["dep"]!]
          ), Kwarg(name: "prefix", opt: true, types: [ListType(types: strL), str]),
        ]
      ),
      Method(
        name: "check_header",
        parent: t,
        returnTypes: boolL,
        args: [
          PositionalArgument(name: "header_name", types: strL),
          Kwarg(name: "args", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [self.types["dep"]!]), self.types["dep"]!]
          ),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [self.types["inc"]!]), self.types["inc"]!]
          ), Kwarg(name: "no_builtin_args", opt: true, types: boolL),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: strL), str]),
          Kwarg(name: "required", opt: true, types: [boolt, self.types["feature"]!]),
        ]
      ), Method(name: "cmd_array", parent: t, returnTypes: [ListType(types: strL)]),
      Method(
        name: "compiles",
        parent: t,
        returnTypes: boolL,
        args: [
          PositionalArgument(name: "code", types: [str, self.types["file"]!]),
          Kwarg(name: "args", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [self.types["dep"]!]), self.types["dep"]!]
          ),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [self.types["inc"]!]), self.types["inc"]!]
          ), Kwarg(name: "name", opt: true, types: strL),
          Kwarg(name: "no_builtin_args", opt: true, types: boolL),
        ]
      ),
      Method(
        name: "compute_int",
        parent: t,
        returnTypes: inttL,
        args: [
          PositionalArgument(name: "expr", types: strL),
          Kwarg(name: "args", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [self.types["dep"]!]), self.types["dep"]!]
          ), Kwarg(name: "guess", opt: true, types: inttL),
          Kwarg(name: "high", opt: true, types: inttL),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [self.types["inc"]!]), self.types["inc"]!]
          ), Kwarg(name: "low", opt: true, types: inttL),
          Kwarg(name: "no_builtin_args", opt: true, types: boolL),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: strL), str]),
        ]
      ),
      Method(
        name: "find_library",
        parent: t,
        returnTypes: [self.types["dep"]!],
        args: [
          PositionalArgument(name: "libname", types: strL),
          Kwarg(name: "dirs", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "disabler", opt: true, types: boolL),
          Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(name: "has_headers", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "header_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "header_dependencies",
            opt: true,
            types: [ListType(types: [self.types["dep"]!]), self.types["dep"]!]
          ),
          Kwarg(
            name: "header_include_directories",
            opt: true,
            types: [ListType(types: [self.types["inc"]!]), self.types["inc"]!]
          ), Kwarg(name: "header_no_builtin_args", opt: true, types: boolL),
          Kwarg(name: "header_prefix", opt: true, types: strL),
          Kwarg(name: "required", opt: true, types: [boolt, self.types["feature"]!]),
          Kwarg(name: "static", opt: true, types: strL),
        ]
      ),
      Method(
        name: "first_supported_argument",
        parent: t,
        returnTypes: [ListType(types: strL)],
        args: [PositionalArgument(name: "arg", varargs: true, opt: true, types: strL)]
      ),
      Method(
        name: "first_supported_link_argument",
        parent: t,
        returnTypes: [ListType(types: strL)],
        args: [PositionalArgument(name: "arg", varargs: true, opt: true, types: strL)]
      ), Method(name: "get_argument_syntax", parent: t, returnTypes: strL),
      Method(
        name: "get_define",
        parent: t,
        returnTypes: strL,
        args: [
          PositionalArgument(name: "definename", types: strL),
          Kwarg(name: "args", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [self.types["dep"]!]), self.types["dep"]!]
          ),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [self.types["inc"]!]), self.types["inc"]!]
          ), Kwarg(name: "no_builtin_args", opt: true, types: boolL),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: strL), str]),
        ]
      ), Method(name: "get_id", parent: t, returnTypes: strL),
      Method(name: "get_linker_id", parent: t, returnTypes: strL),
      Method(
        name: "get_supported_arguments",
        parent: t,
        returnTypes: [ListType(types: strL)],
        args: [
          PositionalArgument(name: "arg", varargs: true, opt: true, types: strL),
          Kwarg(name: "checked", opt: true, types: strL),
        ]
      ),
      Method(
        name: "get_supported_function_attributes",
        parent: t,
        returnTypes: [ListType(types: strL)],
        args: [PositionalArgument(name: "attribs", varargs: true, opt: true, types: strL)]
      ),
      Method(
        name: "get_supported_link_arguments",
        parent: t,
        returnTypes: [ListType(types: strL)],
        args: [PositionalArgument(name: "arg", varargs: true, opt: true, types: strL)]
      ),
      Method(
        name: "has_argument",
        parent: t,
        returnTypes: boolL,
        args: [PositionalArgument(name: "argument", types: strL)]
      ),
      Method(
        name: "has_function",
        parent: t,
        returnTypes: boolL,
        args: [
          PositionalArgument(name: "funcname", types: strL),
          Kwarg(name: "args", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [self.types["dep"]!]), self.types["dep"]!]
          ),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [self.types["inc"]!]), self.types["inc"]!]
          ), Kwarg(name: "no_builtin_args", opt: true, types: boolL),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: strL), str]),
        ]
      ),
      Method(
        name: "has_function_attribute",
        parent: t,
        returnTypes: boolL,
        args: [PositionalArgument(name: "name", types: strL)]
      ),
      Method(
        name: "has_header",
        parent: t,
        returnTypes: boolL,
        args: [
          PositionalArgument(name: "header_name", types: strL),
          Kwarg(name: "args", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [self.types["dep"]!]), self.types["dep"]!]
          ),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [self.types["inc"]!]), self.types["inc"]!]
          ), Kwarg(name: "no_builtin_args", opt: true, types: boolL),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: strL), str]),
          Kwarg(name: "required", opt: true, types: [boolt, self.types["feature"]!]),
        ]
      ),
      Method(
        name: "has_header_symbol",
        parent: t,
        returnTypes: boolL,
        args: [
          PositionalArgument(name: "header", types: strL),
          PositionalArgument(name: "symbol", types: strL),
          Kwarg(name: "args", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [self.types["dep"]!]), self.types["dep"]!]
          ),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [self.types["inc"]!]), self.types["inc"]!]
          ), Kwarg(name: "no_builtin_args", opt: true, types: boolL),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: strL), str]),
          Kwarg(name: "required", opt: true, types: [boolt, self.types["feature"]!]),
        ]
      ),
      Method(
        name: "has_link_argument",
        parent: t,
        returnTypes: boolL,
        args: [PositionalArgument(name: "argument", types: strL)]
      ),
      Method(
        name: "has_member",
        parent: t,
        returnTypes: boolL,
        args: [
          PositionalArgument(name: "typename", types: strL),
          PositionalArgument(name: "membername", types: strL),
          Kwarg(name: "args", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [self.types["dep"]!]), self.types["dep"]!]
          ),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [self.types["inc"]!]), self.types["inc"]!]
          ), Kwarg(name: "no_builtin_args", opt: true, types: boolL),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: strL), str]),
        ]
      ),
      Method(
        name: "has_members",
        parent: t,
        returnTypes: boolL,
        args: [
          PositionalArgument(name: "typename", types: strL),
          PositionalArgument(name: "member", varargs: true, types: strL),
          Kwarg(name: "args", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [self.types["dep"]!]), self.types["dep"]!]
          ),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [self.types["inc"]!]), self.types["inc"]!]
          ), Kwarg(name: "no_builtin_args", opt: true, types: boolL),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: strL), str]),
        ]
      ),
      Method(
        name: "has_multi_arguments",
        parent: t,
        returnTypes: boolL,
        args: [PositionalArgument(name: "arg", varargs: true, opt: true, types: strL)]
      ),
      Method(
        name: "has_multi_link_arguments",
        parent: t,
        returnTypes: boolL,
        args: [PositionalArgument(name: "arg", varargs: true, opt: true, types: strL)]
      ),
      Method(
        name: "has_type",
        parent: t,
        returnTypes: boolL,
        args: [
          PositionalArgument(name: "typename", types: strL),
          Kwarg(name: "args", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [self.types["dep"]!]), self.types["dep"]!]
          ),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [self.types["inc"]!]), self.types["inc"]!]
          ), Kwarg(name: "no_builtin_args", opt: true, types: boolL),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: strL), str]),
        ]
      ),
      Method(
        name: "links",
        parent: t,
        returnTypes: boolL,
        args: [
          PositionalArgument(name: "source", types: [str, self.types["file"]!]),
          Kwarg(name: "args", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [self.types["dep"]!]), self.types["dep"]!]
          ),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [self.types["inc"]!]), self.types["inc"]!]
          ), Kwarg(name: "name", opt: true, types: strL),
          Kwarg(name: "no_builtin_args", opt: true, types: boolL),
        ]
      ),
      Method(
        name: "preprocess",
        parent: t,
        returnTypes: [ListType(types: [self.types["custom_idx"]!])],
        args: [
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ), Kwarg(name: "compile_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [self.types["inc"]!]), self.types["inc"]!]
          ), Kwarg(name: "output", opt: true, types: strL),
        ]
      ),
      Method(
        name: "run",
        parent: t,
        returnTypes: [self.types["runresult"]!],
        args: [
          PositionalArgument(name: "code", types: [str, self.types["file"]!]),
          Kwarg(name: "args", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [self.types["dep"]!]), self.types["dep"]!]
          ),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [self.types["inc"]!]), self.types["inc"]!]
          ), Kwarg(name: "name", opt: true, types: strL),
          Kwarg(name: "no_builtin_args", opt: true, types: boolL),
        ]
      ),
      Method(
        name: "sizeof",
        parent: t,
        returnTypes: inttL,
        args: [
          PositionalArgument(name: "typename", types: strL),
          Kwarg(name: "args", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [self.types["dep"]!]), self.types["dep"]!]
          ),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [self.types["inc"]!]), self.types["inc"]!]
          ), Kwarg(name: "name", opt: true, types: strL),
          Kwarg(name: "no_builtin_args", opt: true, types: boolL),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: strL), str]),
        ]
      ), Method(name: "symbols_have_underscore_prefix", parent: t, returnTypes: boolL),
      Method(name: "version", parent: t, returnTypes: strL),
    ]
    t = self.types["custom_idx"]!
    self.vtables["custom_idx"] = [Method(name: "full_path", parent: t, returnTypes: strL)]
    t = self.types["custom_tgt"]!
    self.vtables["custom_tgt"] = [
      Method(name: "index", parent: t, returnTypes: [self.types["custom_idx"]!]),
      Method(name: "full_path", parent: t, returnTypes: strL),
      Method(
        name: "to_list",
        parent: t,
        returnTypes: [ListType(types: [self.types["custom_idx"]!])]
      ),
    ]
    t = self.types["dep"]!
    self.vtables["dep"] = [
      Method(name: "as_link_whole", parent: t, returnTypes: [t]),
      Method(
        name: "as_system",
        parent: t,
        returnTypes: [t],
        args: [PositionalArgument(name: "value", varargs: false, opt: true, types: strL)]
      ), Method(name: "found", parent: t, returnTypes: boolL),
      Method(
        name: "get_configtool_variable",
        parent: t,
        returnTypes: strL,
        args: [PositionalArgument(name: "var_name", types: strL)]
      ),
      Method(
        name: "get_pkgconfig_variable",
        parent: t,
        returnTypes: strL,
        args: [
          PositionalArgument(name: "var_name", types: strL),
          Kwarg(name: "default", opt: true, types: strL),
          Kwarg(name: "define_variable", opt: true, types: [ListType(types: strL)]),
        ]
      ),
      Method(
        name: "get_variable",
        parent: t,
        returnTypes: strL,
        args: [
          PositionalArgument(name: "varname", opt: true, types: strL),
          Kwarg(name: "cmake", opt: true, types: strL),
          Kwarg(name: "configtool", opt: true, types: strL),
          Kwarg(name: "default_value", opt: true, types: strL),
          Kwarg(name: "internal", opt: true, types: strL),
          Kwarg(name: "pkgconfig", opt: true, types: strL),
          Kwarg(name: "pkgconfig_define", opt: true, types: [ListType(types: strL)]),
        ]
      ), Method(name: "include_type", parent: t, returnTypes: strL),
      Method(name: "name", parent: t, returnTypes: strL),
      Method(
        name: "partial_dependency",
        parent: t,
        returnTypes: [t],
        args: [
          Kwarg(name: "compile_args", opt: true, types: boolL),
          Kwarg(name: "includes", opt: true, types: boolL),
          Kwarg(name: "link_args", opt: true, types: boolL),
          Kwarg(name: "links", opt: true, types: boolL),
          Kwarg(name: "sources", opt: true, types: boolL),
        ]
      ), Method(name: "type_name", parent: t, returnTypes: strL),
      Method(name: "version", parent: t, returnTypes: strL),
    ]
    t = self.types["disabler"]!
    self.vtables["disabler"] = [Method(name: "found", parent: t, returnTypes: boolL)]
    t = self.types["env"]!
    self.vtables["env"] = [
      Method(
        name: "append",
        parent: t,
        args: [
          PositionalArgument(name: "variable", types: strL),
          PositionalArgument(name: "value", varargs: true, opt: true, types: strL),
          Kwarg(name: "separator", opt: true, types: strL),
        ]
      ),
      Method(
        name: "prepend",
        parent: t,
        args: [
          PositionalArgument(name: "variable", types: strL),
          PositionalArgument(name: "value", varargs: true, opt: true, types: strL),
          Kwarg(name: "separator", opt: true, types: strL),
        ]
      ),
      Method(
        name: "set",
        parent: t,
        args: [
          PositionalArgument(name: "variable", types: strL),
          PositionalArgument(name: "value", varargs: true, opt: true, types: strL),
          Kwarg(name: "separator", opt: true, types: strL),
        ]
      ),
    ]
    t = self.types["exe"]!
    self.vtables["exe"] = []
    t = self.types["external_program"]!
    self.vtables["external_program"] = [
      Method(name: "found", parent: t, returnTypes: boolL),
      Method(name: "full_path", parent: t, returnTypes: strL),
      Method(name: "path", parent: t, returnTypes: strL),
      Method(name: "version", parent: t, returnTypes: strL),
    ]
    t = self.types["extracted_obj"]!
    self.vtables["extracted_obj"] = []
    t = self.types["feature"]!
    self.vtables["feature"] = [
      Method(name: "allowed", parent: t, returnTypes: boolL),
      Method(name: "auto", parent: t, returnTypes: boolL),
      Method(
        name: "disable_auto_if",
        parent: t,
        returnTypes: [t],
        args: [PositionalArgument(name: "value", types: boolL)]
      ), Method(name: "disabled", parent: t, returnTypes: boolL),
      Method(name: "enabled", parent: t, returnTypes: boolL),
      Method(
        name: "require",
        parent: t,
        returnTypes: [t],
        args: [
          PositionalArgument(name: "value", types: boolL),
          Kwarg(name: "error_message", opt: true, types: strL),
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
        returnTypes: [self.types["generated_list"]!],
        args: [
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: false,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ), Kwarg(name: "extra_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "preserve_path_from", opt: true, types: strL),
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
    self.vtables["module"] = [Method(name: "found", parent: t, returnTypes: boolL)]
    t = self.types["range"]!
    self.vtables["range"] = []
    t = self.types["runresult"]!
    self.vtables["runresult"] = [
      Method(name: "compiled", parent: t, returnTypes: boolL),
      Method(name: "returncode", parent: t, returnTypes: inttL),
      Method(name: "stderr", parent: t, returnTypes: strL),
      Method(name: "stdout", parent: t, returnTypes: strL),
    ]
    t = self.types["run_tgt"]!
    self.vtables["run_tgt"] = []
    t = self.types["structured_src"]!
    self.vtables["structured_src"] = []
    t = self.types["subproject"]!
    self.vtables["subproject"] = [
      Method(name: "found", parent: t, returnTypes: boolL),
      Method(
        name: "get_variable",
        parent: t,
        returnTypes: [
          self.types["any"]!, ListType(types: [self.types["any"]!]),
          Dict(types: [self.types["any"]!]),
        ],
        args: [
          PositionalArgument(name: "var_name", types: strL),
          PositionalArgument(name: "fallback", opt: true, types: [self.types["any"]!]),
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
        returnTypes: [self.types["cmake_subproject"]!],
        args: [
          PositionalArgument(name: "subproject_name", types: strL),
          Kwarg(name: "options", opt: true, types: [self.types["cmake_subprojectoptions"]!]),
          Kwarg(name: "required", opt: true, types: [boolt, self.types["feature"]!]),
          Kwarg(name: "cmake_options", opt: true, types: [ListType(types: strL)]),
        ]
      ),
      Method(
        name: "subproject_options",
        parent: t,
        returnTypes: [self.types["cmake_subprojectoptions"]!],
        args: []
      ),
      Method(
        name: "write_basic_package_version_file",
        parent: t,
        returnTypes: [],
        args: [
          Kwarg(name: "name", types: strL), Kwarg(name: "version", types: strL),
          Kwarg(name: "compatibility", opt: true, types: strL),
          Kwarg(name: "arch_independent", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
        ]
      ),
      Method(
        name: "configure_package_config_file",
        parent: t,
        returnTypes: [],
        args: [
          Kwarg(name: "name", types: strL),
          Kwarg(name: "input", types: [str, self.types["file"]!]),
          Kwarg(name: "configuration", types: [self.types["cfg_data"]!]),
          Kwarg(name: "install_dir", opt: true, types: strL),
        ]
      ),
    ]
    t = self.types["cmake_subproject"]!
    self.vtables["cmake_subproject"] = [
      Method(
        name: "dependency",
        parent: t,
        returnTypes: [self.types["dep"]!],
        args: [
          PositionalArgument(name: "tgt", types: [self.types["cmake_tgt"]!]),
          Kwarg(name: "include_type", opt: true, types: strL),
        ]
      ),
      Method(
        name: "include_directories",
        parent: t,
        returnTypes: [self.types["inc"]!],
        args: [PositionalArgument(name: "tgt", types: [self.types["cmake_tgt"]!])]
      ),
      Method(
        name: "target",
        parent: t,
        returnTypes: [self.types["tgt"]!],
        args: [PositionalArgument(name: "tgt", types: [self.types["cmake_tgt"]!])]
      ),
      Method(
        name: "target_type",
        parent: t,
        returnTypes: strL,
        args: [PositionalArgument(name: "tgt", types: [self.types["cmake_tgt"]!])]
      ), Method(name: "target_list", parent: t, returnTypes: [ListType(types: strL)], args: []),
      Method(name: "found", parent: t, returnTypes: boolL),
      Method(
        name: "get_variable",
        parent: t,
        returnTypes: [
          self.types["any"]!, ListType(types: [self.types["any"]!]),
          Dict(types: [self.types["any"]!]),
        ],
        args: [
          PositionalArgument(name: "var_name", types: strL),
          PositionalArgument(name: "fallback", opt: true, types: [self.types["any"]!]),
        ]
      ),
    ]
    t = self.types["cmake_subprojectoptions"]!
    self.vtables["cmake_subprojectoptions"] = [
      Method(
        name: "add_cmake_defines",
        parent: t,
        returnTypes: [],
        args: [PositionalArgument(name: "defines", types: [Dict(types: strL)])]
      ),
      Method(
        name: "set_override_option",
        parent: t,
        returnTypes: [],
        args: [
          PositionalArgument(name: "opt", types: strL),
          PositionalArgument(name: "val", types: strL),
          Kwarg(name: "target", opt: true, types: [self.types["cmake_tgt"]!]),
        ]
      ),
      Method(
        name: "set_install",
        parent: t,
        returnTypes: [],
        args: [
          PositionalArgument(name: "install", types: boolL),
          Kwarg(name: "target", opt: true, types: [self.types["cmake_tgt"]!]),
        ]
      ),
      Method(
        name: "append_compile_args",
        parent: t,
        returnTypes: [],
        args: [
          PositionalArgument(name: "language", types: strL),
          PositionalArgument(name: "arg", varargs: true, types: strL),
          Kwarg(name: "target", opt: true, types: [self.types["cmake_tgt"]!]),
        ]
      ),
      Method(
        name: "append_link_args",
        parent: t,
        returnTypes: [],
        args: [
          PositionalArgument(name: "language", types: strL),
          PositionalArgument(name: "arg", varargs: true, types: strL),
          Kwarg(name: "target", opt: true, types: [self.types["cmake_tgt"]!]),
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
        returnTypes: strL,
        args: [PositionalArgument(name: "version_string", varargs: true, types: strL)]
      ),
      Method(
        name: "nvcc_arch_flags",
        parent: t,
        returnTypes: [ListType(types: strL)],
        args: [
          PositionalArgument(name: "architecture_set", varargs: true, opt: true, types: strL),
          Kwarg(name: "detected", opt: true, types: [str, ListType(types: strL)]),
        ]
      ),
      Method(
        name: "nvcc_arch_readable",
        parent: t,
        returnTypes: [ListType(types: strL)],
        args: [
          PositionalArgument(name: "architecture_set", varargs: true, opt: true, types: strL),
          Kwarg(name: "detected", opt: true, types: [str, ListType(types: strL)]),
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
          PositionalArgument(name: "name", types: strL),
          PositionalArgument(name: "source", types: strL),
          Kwarg(name: "authors", opt: true, types: [str, ListType(types: strL)]),
          Kwarg(name: "description", opt: true, types: strL),
          // TODO: Derived just based on guessing
          Kwarg(name: "copyright", opt: true, types: [str, ListType(types: strL)]),
          Kwarg(name: "license", opt: true, types: [str, ListType(types: strL)]),
          Kwarg(name: "sourceFiles", opt: true, types: [str, ListType(types: strL)]),
          Kwarg(name: "targetType", opt: true, types: strL),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [self.types["dep"]!, str])]
          ),
        ]
      )
    ]
    t = self.types["external_project"]!
    self.vtables["external_project"] = [
      Method(
        name: "dependency",
        parent: t,
        returnTypes: [self.types["dep"]!],
        args: [
          PositionalArgument(name: "subdir", types: strL),
          Kwarg(name: "subdir", opt: true, types: strL),
        ]
      )
    ]
    t = self.types["external_project_module"]!
    self.vtables["external_project_module"] = [
      Method(
        name: "add_project",
        parent: t,
        returnTypes: [self.types["external_project"]!],
        args: [
          PositionalArgument(name: "script", types: strL),
          Kwarg(name: "configure_options", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "cross_configure_options", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "verbose", opt: true, types: boolL),
          Kwarg(
            name: "env",
            opt: true,
            types: [self.types["env"]!, ListType(types: strL), Dict(types: strL)]
          ),
          Kwarg(
            name: "depends",
            opt: true,
            types: [ListType(types: [self.types["build_tgt"]!, self.types["custom_tgt"]!])]
          ),
        ]
      )
    ]
    t = self.types["fs_module"]!
    self.vtables["fs_module"] = [
      Method(
        name: "exists",
        parent: t,
        returnTypes: boolL,
        args: [PositionalArgument(name: "file", types: strL)]
      ),
      Method(
        name: "is_dir",
        parent: t,
        returnTypes: boolL,
        args: [PositionalArgument(name: "file", types: strL)]
      ),
      Method(
        name: "is_file",
        parent: t,
        returnTypes: boolL,
        args: [PositionalArgument(name: "file", types: strL)]
      ),
      Method(
        name: "is_symlink",
        parent: t,
        returnTypes: boolL,
        args: [PositionalArgument(name: "file", types: [str, self.types["file"]!])]
      ),
      Method(
        name: "is_absolute",
        parent: t,
        returnTypes: boolL,
        args: [PositionalArgument(name: "file", types: strL)]
      ),
      Method(
        name: "hash",
        parent: t,
        returnTypes: strL,
        args: [
          PositionalArgument(name: "file", types: [str, self.types["file"]!]),
          PositionalArgument(name: "hash_algorithm", types: strL),
        ]
      ),
      Method(
        name: "size",
        parent: t,
        returnTypes: inttL,
        args: [PositionalArgument(name: "file", types: [str, self.types["file"]!])]
      ),
      Method(
        name: "is_samepath",
        parent: t,
        returnTypes: strL,
        args: [
          PositionalArgument(name: "path1", types: [str, self.types["file"]!]),
          PositionalArgument(name: "path2", types: [str, self.types["file"]!]),
        ]
      ),
      Method(
        name: "expanduser",
        parent: t,
        returnTypes: strL,
        args: [PositionalArgument(name: "file", types: strL)]
      ),
      Method(
        name: "as_posix",
        parent: t,
        returnTypes: strL,
        args: [PositionalArgument(name: "file", types: strL)]
      ),
      Method(
        name: "replace_suffix",
        parent: t,
        returnTypes: strL,
        args: [
          PositionalArgument(name: "file", types: strL),
          PositionalArgument(name: "suffix", types: strL),
        ]
      ),
      Method(
        name: "parent",
        parent: t,
        returnTypes: strL,
        args: [PositionalArgument(name: "file", types: [self.types["file"]!, str])]
      ),
      Method(
        name: "name",
        parent: t,
        returnTypes: strL,
        args: [PositionalArgument(name: "file", types: [self.types["file"]!, str])]
      ),
      Method(
        name: "stem",
        parent: t,
        returnTypes: strL,
        args: [PositionalArgument(name: "file", types: [self.types["file"]!, str])]
      ),
      Method(
        name: "read",
        parent: t,
        returnTypes: strL,
        args: [
          PositionalArgument(name: "file", types: [self.types["file"]!, str]),
          Kwarg(name: "encoding", opt: true, types: strL),
        ]
      ),
      Method(
        name: "copyfile",
        parent: t,
        returnTypes: [self.types["custom_tgt"]!],
        args: [
          PositionalArgument(name: "src", types: [self.types["file"]!, str]),
          PositionalArgument(name: "dst", opt: true, types: strL),
          Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: [str, intt])]),
        ]
      ),
    ]
    t = self.types["gnome_module"]!
    self.vtables["gnome_module"] = [
      Method(
        name: "compile_resources",
        parent: t,
        returnTypes: [ListType(types: [self.types["build_tgt"]!])],
        args: [
          PositionalArgument(name: "id", types: strL),
          PositionalArgument(
            name: "input",
            types: [
              ListType(types: [
                str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
                self.types["generated_list"]!,
              ])
            ]
          ), Kwarg(name: "c_name", opt: true, types: strL),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [
              ListType(types: [
                self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              ])
            ]
          ), Kwarg(name: "export", opt: true, types: boolL),
          Kwarg(name: "extra_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "gresource_bundle", opt: true, types: boolL),
          Kwarg(name: "build_by_default", opt: true, types: boolL),
          Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_header", opt: true, types: boolL),
          Kwarg(name: "source_dir", opt: true, types: [ListType(types: strL)]),
        ]
      ),
      Method(
        name: "generate_gir",
        parent: t,
        returnTypes: [ListType(types: [self.types["custom_tgt"]!])],
        args: [
          PositionalArgument(
            name: "file",
            varargs: true,
            types: [self.types["exe"]!, self.types["lib"]!]
          ), Kwarg(name: "dependencies", opt: true, types: [ListType(types: [self.types["dep"]!])]),
          Kwarg(name: "extra_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "export_packages", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "sources",
            opt: true,
            types: [
              ListType(types: [
                str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              ])
            ]
          ), Kwarg(name: "nsversion", opt: true, types: strL),
          Kwarg(name: "namespace", opt: true, types: strL),
          Kwarg(name: "identifier_prefix", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "includes",
            opt: true,
            types: [ListType(types: [str, self.types["custom_tgt"]!])]
          ), Kwarg(name: "header", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "symbol_prefix", opt: true, types: strL),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [str, self.types["inc"]!])]
          ), Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_gir", opt: true, types: boolL),
          Kwarg(name: "install_dir_gir", opt: true, types: [str, boolt]),
          Kwarg(name: "install_typelib", opt: true, types: boolL),
          Kwarg(name: "install_dir_typelib", opt: true, types: [str, boolt]),
          Kwarg(name: "link_with", opt: true, types: [ListType(types: [self.types["lib"]!])]),
          Kwarg(name: "symbok_prefix", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "fatal_warnings", opt: true, types: boolL),
          Kwarg(name: "build_by_default", opt: true, types: boolL),
        ]
      ),
      Method(
        name: "genmarshal",
        parent: t,
        returnTypes: [ListType(types: [self.types["custom_tgt"]!])],
        args: [
          PositionalArgument(name: "basename", types: strL),
          Kwarg(
            name: "depends",
            opt: true,
            types: [ListType(types: [self.types["build_tgt"]!, self.types["custom_tgt"]!])]
          ), Kwarg(name: "depend_files", opt: true, types: [str, self.types["file"]!]),
          Kwarg(name: "extra_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_header", opt: true, types: boolL),
          Kwarg(name: "internal", opt: true, types: boolL),
          Kwarg(name: "nostdinc", opt: true, types: boolL),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "skip_source", opt: true, types: boolL),
          Kwarg(name: "sources", types: [ListType(types: [str, self.types["file"]!])]),
          Kwarg(name: "stdinc", opt: true, types: boolL),
          Kwarg(name: "valist_marshallers", opt: true, types: boolL),
        ]
      ),
      Method(
        name: "mkenums",
        parent: t,
        returnTypes: [ListType(types: [self.types["custom_tgt"]!])],
        args: [
          PositionalArgument(name: "name", types: strL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_header", opt: true, types: boolL),
          Kwarg(
            name: "sources",
            types: [
              ListType(types: [
                str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
                self.types["generated_list"]!,
              ])
            ]
          ), Kwarg(name: "symbol_prefix", opt: true, types: strL),
          Kwarg(name: "identifier_prefix", opt: true, types: strL),
          Kwarg(
            name: "depends",
            opt: true,
            types: [ListType(types: [self.types["build_tgt"]!, self.types["custom_tgt"]!])]
          ), Kwarg(name: "c_template", opt: true, types: [self.types["file"]!, str]),
          Kwarg(name: "h_template", opt: true, types: [self.types["file"]!, str]),
          Kwarg(name: "comments", opt: true, types: strL),
          Kwarg(name: "eprod", opt: true, types: strL),
          Kwarg(name: "fhead", opt: true, types: strL),
          Kwarg(name: "fprod", opt: true, types: strL),
          Kwarg(name: "ftail", opt: true, types: strL),
          Kwarg(name: "vhead", opt: true, types: strL),
          Kwarg(name: "vprod", opt: true, types: strL),
          Kwarg(name: "vtail", opt: true, types: strL),
        ]
      ),
      Method(
        name: "mkenums_simple",
        parent: t,
        returnTypes: [ListType(types: [self.types["custom_tgt"]!])],
        args: [
          PositionalArgument(name: "name", types: strL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_header", opt: true, types: boolL),
          Kwarg(
            name: "sources",
            types: [
              ListType(types: [
                str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
                self.types["generated_list"]!,
              ])
            ]
          ), Kwarg(name: "symbol_prefix", opt: true, types: strL),
          Kwarg(name: "identifier_prefix", opt: true, types: strL),
          Kwarg(name: "body_prefix", opt: true, types: strL),
          Kwarg(name: "decorator", opt: true, types: strL),
          Kwarg(name: "function_prefix", opt: true, types: strL),
          Kwarg(name: "header_prefix", opt: true, types: strL),
        ]
      ),
      Method(
        name: "compile_schemas",
        parent: t,
        returnTypes: [self.types["custom_tgt"]!],
        args: [
          Kwarg(name: "build_by_default", opt: true, types: boolL),
          Kwarg(name: "depend_files", opt: true, types: [str, self.types["file"]!]),
        ]
      ),
      Method(
        name: "gdbus_codegen",
        parent: t,
        returnTypes: [ListType(types: [self.types["custom_tgt"]!])],
        args: [
          PositionalArgument(name: "name", types: strL),
          PositionalArgument(
            name: "file",
            varargs: true,
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ), Kwarg(name: "extra_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "interface_prefix", opt: true, types: strL),
          Kwarg(name: "namespace", opt: true, types: strL),
          Kwarg(name: "object_manager", opt: true, types: boolL),
          Kwarg(name: "annotations", opt: true, types: [ListType(types: [ListType(types: strL)])]),
          Kwarg(name: "install_header", opt: true, types: boolL),
          Kwarg(name: "docbook", opt: true, types: strL),
          Kwarg(name: "autocleanup", opt: true, types: strL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "build_by_default", opt: true, types: boolL),
          Kwarg(
            name: "sources",
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ),
        ]
      ),
      Method(
        name: "generate_vapi",
        parent: t,
        returnTypes: [self.types["dep"]!],
        args: [
          PositionalArgument(name: "name", types: strL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "sources", types: [ListType(types: [str, self.types["custom_tgt"]!])]),
          Kwarg(name: "vapi_dirs", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "metadata_dirs", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "gir_dirs", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "packages", opt: true, types: [ListType(types: [str, self.types["dep"]!])]),
        ]
      ),
      Method(
        name: "yelp",
        parent: t,
        returnTypes: [],
        args: [
          PositionalArgument(name: "name", types: strL),
          PositionalArgument(name: "file", varargs: true, opt: true, types: strL),
          Kwarg(name: "languages", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "media", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "sources", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "symlink_media", opt: true, types: boolL),
        ]
      ),
      Method(
        name: "gtkdoc",
        parent: t,
        returnTypes: [ListType(types: [self.types["custom_tgt"]!])],
        args: [
          PositionalArgument(name: "name", types: strL),
          Kwarg(name: "c_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "check", opt: true, types: boolL),
          Kwarg(
            name: "content_files",
            opt: true,
            types: [
              ListType(types: [
                str, self.types["file"]!, self.types["generated_list"]!, self.types["custom_tgt"]!,
                self.types["custom_idx"]!,
              ])
            ]
          ),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [self.types["dep"]!, self.types["lib"]!])]
          ),
          Kwarg(
            name: "expand_content_files",
            opt: true,
            types: [ListType(types: [str, self.types["file"]!])]
          ), Kwarg(name: "fixref_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "gobject_typesfile",
            opt: true,
            types: [ListType(types: [str, self.types["file"]!])]
          ), Kwarg(name: "html_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "html_assets",
            opt: true,
            types: [ListType(types: [str, self.types["file"]!])]
          ), Kwarg(name: "ignore_headers", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [str, self.types["inc"]!])]
          ), Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "main_sgml", opt: true, types: strL),
          Kwarg(name: "main_xml", opt: true, types: strL),
          Kwarg(name: "fixxref_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "mkdb_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "mode", opt: true, types: strL),
          Kwarg(name: "module_version", opt: true, types: strL),
          Kwarg(name: "namespace", opt: true, types: strL),
          Kwarg(name: "scan_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "scanobj_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "src_dir", opt: true, types: [ListType(types: [str, self.types["inc"]!])]),
        ]
      ),
      Method(
        name: "gtkdoc_html_dir",
        parent: t,
        returnTypes: strL,
        args: [PositionalArgument(name: "name", types: strL)]
      ),
      Method(
        name: "post_install",
        parent: t,
        returnTypes: [],
        args: [
          Kwarg(name: "glib_compile_schemas", opt: true, types: boolL),
          Kwarg(name: "gtk_update_icon_cache", opt: true, types: boolL),
          Kwarg(name: "update_desktop_database", opt: true, types: boolL),
          Kwarg(name: "update_mime_database", opt: true, types: boolL),
          Kwarg(name: "gio_querymodules", opt: true, types: [ListType(types: strL)]),
        ]
      ),
    ]
    t = self.types["hotdoc_module"]!
    self.vtables["hotdoc_module"] = [
      Method(
        name: "has_extensions",
        parent: t,
        returnTypes: boolL,
        args: [PositionalArgument(name: "extensions", varargs: true, types: strL)]
      ),
      Method(
        name: "generate_doc",
        parent: t,
        returnTypes: [self.types["hotdoc_target"]!],
        args: [
          PositionalArgument(name: "project_name", types: strL),
          Kwarg(
            name: "sitemap",
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ),
          Kwarg(
            name: "index",
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "project_version", types: strL),
          Kwarg(
            name: "html_extra_theme",
            opt: true,
            types: [

            ]
          ), Kwarg(name: "include_paths", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [
              ListType(types: [
                str, self.types["lib"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              ])
            ]
          ),
          Kwarg(
            name: "depends",
            opt: true,
            types: [ListType(types: [self.types["custom_tgt"]!, self.types["custom_idx"]!])]
          ), Kwarg(name: "gi_c_source_roots", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "extra_assets", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "extra_extension_paths", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "subprojects",
            opt: true,
            types: [ListType(types: [self.types["hotdoc_target"]!])]
          ), Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "gi_c_sources", opt: true, types: strlistL),
          Kwarg(name: "gi_c_source_filters", opt: true, types: strlistL),
          Kwarg(name: "gi_index", opt: true, types: strL),
          Kwarg(name: "gi_smart_index", opt: true, types: strL),
          Kwarg(name: "gi_sources", opt: true, types: strlistL),
          Kwarg(name: "disable_incremental_build", opt: true, types: boolL),
          Kwarg(name: "gi_order_generated_subpages", opt: true, types: boolL),
          Kwarg(name: "syntax_highlighting_activate", opt: true, types: boolL),
          Kwarg(name: "html_theme", opt: true, types: strL),
          Kwarg(name: "html_list_plugins_page", opt: true, types: strL),
          Kwarg(name: "devhelp_activate", opt: true, types: boolL),
          Kwarg(name: "devhelp_online", opt: true, types: strL),
          Kwarg(name: "build_always_stale", opt: true, types: boolL),
          Kwarg(name: "edit_on_github_repository", opt: true, types: strL),
          Kwarg(name: "previous_symbol_index", opt: true, types: strL),
          Kwarg(name: "fatal_warnings", opt: true, types: boolL),
          Kwarg(name: "gst_index", opt: true, types: strL),
          Kwarg(name: "gst_smart_index", opt: true, types: boolL),
          Kwarg(name: "c_smart_index", opt: true, types: boolL),
          Kwarg(name: "c_sources", opt: true, types: strlistL),
          Kwarg(name: "languages", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "gst_c_sources", opt: true, types: strlistL),
          Kwarg(name: "gst_cache_file", opt: true, types: strL),
          Kwarg(name: "gst_plugin_name", opt: true, types: strL),
          Kwarg(name: "c_flags", opt: true, types: [str, strlist]),
          Kwarg(name: "extra_c_flags", opt: true, types: [str, strlist]),
          Kwarg(name: "c_order_generated_subpages", opt: true, types: boolL),
          Kwarg(name: "c_sources", opt: true, types: strlistL),
          Kwarg(name: "c_source_filters", opt: true, types: strlistL),
          Kwarg(name: "gst_order_generated_subpages", opt: true, types: boolL),
          Kwarg(name: "gst_list_plugins_page", opt: true, types: strL),
          Kwarg(name: "gst_dl_sources", opt: true, types: [str, strlist]),
          Kwarg(name: "gst_c_source_filters", opt: true, types: strlistL),
          Kwarg(name: "c_smart_index", opt: true, types: strL),
          Kwarg(name: "c_index", opt: true, types: strL),
        ]
      ),
    ]
    t = self.types["hotdoc_target"]!
    self.vtables["hotdoc_target"] = [Method(name: "config_path", parent: t, returnTypes: strL)]
    t = self.types["i18n_module"]!
    self.vtables["i18n_module"] = [
      Method(
        name: "gettext",
        parent: t,
        returnTypes: [
          ListType(types: [ListType(types: [self.types["custom_tgt"]!]), self.types["run_tgt"]!])
        ],
        args: [
          PositionalArgument(name: "packagename", types: strL),
          Kwarg(name: "args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "data_dirs", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "preset", opt: true, types: strL),
          Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "languages", opt: true, types: [ListType(types: strL)]),
        ]
      ),
      Method(
        name: "merge_file",
        parent: t,
        returnTypes: [self.types["custom_tgt"]!],
        args: [
          Kwarg(name: "output", types: strL),
          Kwarg(name: "args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "data_dirs", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "po_dir", types: strL), Kwarg(name: "type", opt: true, types: strL),
          Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(
            name: "input",
            opt: true,
            types: [
              ListType(types: [
                str, self.types["file"]!, self.types["external_program"]!, self.types["build_tgt"]!,
                self.types["custom_tgt"]!, self.types["custom_idx"]!, self.types["extracted_obj"]!,
                self.types["generated_list"]!,
              ])
            ]
          ), Kwarg(name: "build_by_default", opt: true, types: boolL),
        ]
      ),
      Method(
        name: "itstool_join",
        parent: t,
        returnTypes: [self.types["custom_tgt"]!],
        args: [
          Kwarg(name: "output", types: strL),
          Kwarg(name: "args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "data_dirs", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "mo_targets", types: [ListType(types: [self.types["custom_tgt"]!])]),
          Kwarg(name: "its_files", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "type", opt: true, types: strL),
          Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(
            name: "input",
            opt: true,
            types: [
              ListType(types: [
                str, self.types["file"]!, self.types["external_program"]!, self.types["build_tgt"]!,
                self.types["custom_tgt"]!, self.types["custom_idx"]!, self.types["extracted_obj"]!,
                self.types["generated_list"]!,
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
        returnTypes: [ListType(types: [self.types["run_tgt"]!, self.types["custom_tgt"]!])],
        args: [
          PositionalArgument(name: "project_name", types: strL),
          PositionalArgument(
            name: "files",
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ),
          Kwarg(
            name: "constraint_file",
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ),
        ]
      )
    ]
    t = self.types["java_module"]!
    self.vtables["java_module"] = [
      Method(
        name: "generate_native_header",
        parent: t,
        returnTypes: [self.types["custom_tgt"]!],
        args: [
          PositionalArgument(
            name: "files",
            varargs: true,
            opt: true,
            types: [
              str, self.types["file"]!, self.types["tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ), Kwarg(name: "package", opt: true, types: strL),
        ]
      ),
      Method(
        name: "generate_native_headers",
        parent: t,
        returnTypes: [self.types["custom_tgt"]!],
        args: [
          PositionalArgument(
            name: "files",
            varargs: true,
            opt: true,
            types: [
              str, self.types["file"]!, self.types["tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ), Kwarg(name: "classes", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "package", opt: true, types: strL),
        ]
      ),
      Method(
        name: "native_headers",
        parent: t,
        returnTypes: [self.types["custom_tgt"]!],
        args: [
          PositionalArgument(
            name: "files",
            varargs: true,
            opt: true,
            types: [
              str, self.types["file"]!, self.types["tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ), Kwarg(name: "classes", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "package", opt: true, types: strL),
        ]
      ),
    ]
    t = self.types["keyval_module"]!
    self.vtables["keyval_module"] = [
      Method(
        name: "load",
        parent: t,
        returnTypes: [Dict(types: strL)],
        args: [PositionalArgument(name: "file", types: [self.types["file"]!, str])]
      )
    ]
    t = self.types["pkgconfig_module"]!
    self.vtables["pkgconfig_module"] = [
      Method(
        name: "generate",
        parent: t,
        returnTypes: [self.types["external_program"]!],
        args: [
          PositionalArgument(name: "libs", opt: true, types: [self.types["lib"]!]),
          Kwarg(name: "d_module_versions", opt: true, types: [ListType(types: [str, intt])]),
          Kwarg(name: "install_dir", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "conflicts", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "dataonly", opt: true, types: boolL),
          Kwarg(name: "description", opt: true, types: strL),
          Kwarg(name: "extra_cflags", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "filebase", opt: true, types: strL),
          Kwarg(name: "subdirs", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "name", opt: true, types: strL), Kwarg(name: "url", opt: true, types: strL),
          Kwarg(name: "version", opt: true, types: strL),
          Kwarg(name: "variables", opt: true, types: [ListType(types: strL), Dict(types: strL)]),
          Kwarg(
            name: "unescaped_variables",
            opt: true,
            types: [ListType(types: strL), Dict(types: strL)]
          ),
          Kwarg(
            name: "uninstalled_variables",
            opt: true,
            types: [ListType(types: strL), Dict(types: strL)]
          ),
          Kwarg(
            name: "unescaped_uninstalled_variables",
            opt: true,
            types: [ListType(types: strL), Dict(types: strL)]
          ),
          Kwarg(
            name: "libraries",
            opt: true,
            types: [
              ListType(types: [
                str, self.types["dep"]!, self.types["lib"]!, self.types["custom_tgt"]!,
                self.types["custom_idx"]!,
              ])
            ]
          ),
          Kwarg(
            name: "libraries_private",
            opt: true,
            types: [
              ListType(types: [
                str, self.types["dep"]!, self.types["lib"]!, self.types["custom_tgt"]!,
                self.types["custom_idx"]!,
              ])
            ]
          ),
          Kwarg(
            name: "requires",
            opt: true,
            types: [ListType(types: [str, self.types["dep"]!, self.types["lib"]!])]
          ),
          Kwarg(
            name: "requires_private",
            opt: true,
            types: [ListType(types: [str, self.types["dep"]!, self.types["lib"]!])]
          ), Kwarg(name: "install", opt: true, types: boolL),
        ]
      )
    ]
    t = self.types["python_module"]!
    self.vtables["python_module"] = [
      Method(
        name: "find_installation",
        parent: t,
        returnTypes: [self.types["python_installation"]!],
        args: [
          PositionalArgument(name: "name_or_path", opt: true, types: strL),
          Kwarg(name: "required", opt: true, types: boolL),
          Kwarg(name: "disabler", opt: true, types: boolL),
          Kwarg(name: "modules", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "pure", opt: true, types: boolL),
        ]
      )
    ]
    t = self.types["python_installation"]!
    self.vtables["python_installation"] = [
      Method(name: "path", parent: t, returnTypes: strL, args: []),
      Method(
        name: "extension_module",
        parent: t,
        returnTypes: [self.types["build_tgt"]!],
        args: [
          PositionalArgument(name: "target_name", types: strL),
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ), Kwarg(name: "c_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "cpp_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "cs_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "d_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "fortran_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "java_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "objc_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "objcpp_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "rust_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "vala_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "cython_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "nasm_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "masm_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "c_pch", opt: true, types: strL),
          Kwarg(name: "cpp_pch", opt: true, types: strL),
          Kwarg(name: "build_by_default", opt: true, types: boolL),
          Kwarg(name: "build_rpath", opt: true, types: strL),
          Kwarg(name: "d_debug", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "d_import_dirs", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "d_module_versions", opt: true, types: [ListType(types: [str, intt])]),
          Kwarg(name: "d_unittest", opt: true, types: boolL),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [self.types["dep"]!])]),
          Kwarg(
            name: "extra_files",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "gnu_symbol_visibility", opt: true, types: strL),
          Kwarg(name: "gui_app", opt: true, types: boolL),
          Kwarg(name: "implicit_include_directories", opt: true, types: boolL),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [str, self.types["inc"]!])]
          ), Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: [str, intt])]),
          Kwarg(name: "install_rpath", opt: true, types: strL),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "link_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "link_depends",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "link_language", opt: true, types: strL),
          Kwarg(
            name: "link_whole",
            opt: true,
            types: [
              ListType(types: [
                self.types["lib"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              ])
            ]
          ),
          Kwarg(
            name: "link_with",
            opt: true,
            types: [
              ListType(types: [
                self.types["lib"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              ])
            ]
          ), Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(
            name: "objects",
            opt: true,
            types: [ListType(types: [self.types["extracted_obj"]!, self.types["file"]!, str])]
          ), Kwarg(name: "override_options", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "rust_crate_type", opt: true, types: strL),
          Kwarg(
            name: "sources",
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!, self.types["structured_src"]!,
            ]
          ),
          Kwarg(
            name: "vs_module_defs",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "win_subsystem", opt: true, types: strL),
          Kwarg(name: "subdir", opt: true, types: strL),
        ]
      ),
      Method(
        name: "dependency",
        parent: t,
        returnTypes: [self.types["dep"]!],
        args: [
          Kwarg(name: "allow_fallback", opt: true, types: boolL),
          Kwarg(name: "default_options", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "disabler", opt: true, types: boolL),
          Kwarg(name: "fallback", opt: true, types: [str, ListType(types: strL)]),
          Kwarg(name: "include_type", opt: true, types: strL),
          Kwarg(name: "language", opt: true, types: strL),
          Kwarg(name: "method", opt: true, types: strL),
          Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(name: "not_found_message", opt: true, types: strL),
          Kwarg(name: "required", opt: true, types: [boolt, self.types["feature"]!]),
          Kwarg(name: "static", opt: true, types: boolL),
          Kwarg(name: "version", opt: true, types: strL),
          Kwarg(name: "disabler", opt: true, types: boolL),
          Kwarg(name: "embed", opt: true, types: boolL),
        ]
      ),
      Method(
        name: "install_sources",
        parent: t,
        returnTypes: [],
        args: [
          PositionalArgument(
            name: "file",
            varargs: true,
            opt: true,
            types: [str, self.types["file"]!]
          ), Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: [str, intt])]),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "preserve_path", opt: true, types: boolL),
          Kwarg(name: "rename", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "sources", opt: true, types: [ListType(types: [self.types["file"]!, str])]),
          Kwarg(name: "pure", opt: true, types: boolL),
          Kwarg(name: "subdir", opt: true, types: strL),
        ]
      ),
      Method(
        name: "get_install_dir",
        parent: t,
        returnTypes: strL,
        args: [
          Kwarg(name: "pure", opt: true, types: boolL),
          Kwarg(name: "subdir", opt: true, types: strL),
        ]
      ), Method(name: "language_version", parent: t, returnTypes: strL, args: []),
      Method(
        name: "get_path",
        parent: t,
        returnTypes: strL,
        args: [
          PositionalArgument(name: "path_name", types: strL),
          PositionalArgument(name: "fallback", opt: true, types: [self.types["any"]!]),
        ]
      ),
      Method(
        name: "has_path",
        parent: t,
        returnTypes: boolL,
        args: [PositionalArgument(name: "path_name", types: strL)]
      ),
      Method(
        name: "get_variable",
        parent: t,
        returnTypes: [
          self.types["any"]!, ListType(types: [self.types["any"]!]),
          Dict(types: [self.types["any"]!]),
        ],
        args: [
          PositionalArgument(name: "variable_name", types: strL),
          PositionalArgument(name: "fallback", opt: true, types: [self.types["any"]!]),
        ]
      ),
      Method(
        name: "has_variable",
        parent: t,
        returnTypes: boolL,
        args: [PositionalArgument(name: "variable_name", types: strL)]
      ),
    ]
    t = self.types["python3_module"]!
    self.vtables["python3_module"] = [
      Method(
        name: "find_python",
        parent: t,
        returnTypes: [self.types["external_program"]!],
        args: []
      ),
      Method(
        name: "extension_module",
        parent: t,
        returnTypes: [self.types["build_tgt"]!],
        args: [
          PositionalArgument(name: "target_name", types: strL),
          PositionalArgument(
            name: "source",
            varargs: true,
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ), Kwarg(name: "c_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "cpp_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "cs_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "d_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "fortran_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "java_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "objc_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "objcpp_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "rust_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "vala_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "cython_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "nasm_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "masm_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "c_pch", opt: true, types: strL),
          Kwarg(name: "cpp_pch", opt: true, types: strL),
          Kwarg(name: "build_by_default", opt: true, types: boolL),
          Kwarg(name: "build_rpath", opt: true, types: strL),
          Kwarg(name: "d_debug", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "d_import_dirs", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "d_module_versions", opt: true, types: [ListType(types: [str, intt])]),
          Kwarg(name: "d_unittest", opt: true, types: boolL),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [self.types["dep"]!])]),
          Kwarg(
            name: "extra_files",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "gnu_symbol_visibility", opt: true, types: strL),
          Kwarg(name: "gui_app", opt: true, types: boolL),
          Kwarg(name: "implicit_include_directories", opt: true, types: boolL),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [str, self.types["inc"]!])]
          ), Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: [str, intt])]),
          Kwarg(name: "install_rpath", opt: true, types: strL),
          Kwarg(name: "install_tag", opt: true, types: strL),
          Kwarg(name: "link_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "link_depends",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "link_language", opt: true, types: strL),
          Kwarg(
            name: "link_whole",
            opt: true,
            types: [
              ListType(types: [
                self.types["lib"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              ])
            ]
          ),
          Kwarg(
            name: "link_with",
            opt: true,
            types: [
              ListType(types: [
                self.types["lib"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              ])
            ]
          ), Kwarg(name: "name_prefix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "name_suffix", opt: true, types: [str, ListType(types: [])]),
          Kwarg(name: "native", opt: true, types: boolL),
          Kwarg(
            name: "objects",
            opt: true,
            types: [ListType(types: [self.types["extracted_obj"]!, self.types["file"]!, str])]
          ), Kwarg(name: "override_options", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "rust_crate_type", opt: true, types: strL),
          Kwarg(
            name: "sources",
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!, self.types["structured_src"]!,
            ]
          ),
          Kwarg(
            name: "vs_module_defs",
            opt: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ), Kwarg(name: "win_subsystem", opt: true, types: strL),
        ]
      ), Method(name: "language_version", parent: t, returnTypes: strL, args: []),
      Method(
        name: "sysconfig_path",
        parent: t,
        returnTypes: strL,
        args: [PositionalArgument(name: "path_name", types: strL)]
      ),
    ]
    t = self.types["qt4_module"]!
    self.vtables["qt4_module"] = [
      Method(
        name: "compile_resources",
        parent: t,
        returnTypes: [ListType(types: [self.types["custom_tgt"]!])],
        args: [
          Kwarg(name: "name", opt: true, types: strL),
          Kwarg(
            name: "sources",
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ), Kwarg(name: "extra_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "method", opt: true, types: strL),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "compile_ui",
        parent: t,
        returnTypes: [ListType(types: [self.types["custom_tgt"]!])],
        args: [
          Kwarg(
            name: "sources",
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ), Kwarg(name: "extra_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "method", opt: true, types: strL),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "compile_moc",
        parent: t,
        returnTypes: [ListType(types: [self.types["custom_tgt"]!])],
        args: [
          Kwarg(
            name: "sources",
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ),
          Kwarg(
            name: "headers",
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ), Kwarg(name: "extra_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "method", opt: true, types: strL),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [self.types["dep"]!, self.types["lib"]!])]
          ),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [self.types["inc"]!, str])]
          ),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "preprocess",
        parent: t,
        returnTypes: [ListType(types: [self.types["custom_tgt"]!])],
        args: [
          PositionalArgument(name: "name", opt: true, types: strL),
          Kwarg(name: "sources", opt: true, types: [ListType(types: [str, self.types["file"]!])]),
          Kwarg(
            name: "qresources",
            opt: true,
            types: [ListType(types: [str, self.types["file"]!])]
          ),
          Kwarg(
            name: "ui_files",
            opt: true,
            types: [ListType(types: [str, self.types["file"]!, self.types["custom_tgt"]!])]
          ),
          Kwarg(
            name: "moc_sources",
            opt: true,
            types: [ListType(types: [str, self.types["file"]!, self.types["custom_tgt"]!])]
          ),
          Kwarg(
            name: "moc_headers",
            opt: true,
            types: [ListType(types: [str, self.types["file"]!, self.types["custom_tgt"]!])]
          ), Kwarg(name: "moc_extra_arguments", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "rcc_extra_arguments", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "uic_extra_arguments", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "method", opt: true, types: strL),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [self.types["dep"]!, self.types["lib"]!])]
          ),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [self.types["inc"]!, str])]
          ),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "compile_translations",
        parent: t,
        returnTypes: [ListType(types: [self.types["custom_tgt"]!])],
        args: [
          Kwarg(name: "build_by_default", opt: true, types: boolL),
          Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(
            name: "ts_files",
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ), Kwarg(name: "rcc_extra_arguments", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "method", opt: true, types: strL),
          Kwarg(name: "qresource", opt: true, types: strL),
        ]
      ),
      Method(
        name: "has_tools",
        parent: t,
        returnTypes: boolL,
        args: [
          Kwarg(name: "required", opt: true, types: boolL),
          Kwarg(name: "method", opt: true, types: strL),
        ]
      ),
    ]
    t = self.types["qt5_module"]!
    self.vtables["qt5_module"] = [
      Method(
        name: "compile_resources",
        parent: t,
        returnTypes: [ListType(types: [self.types["custom_tgt"]!])],
        args: [
          Kwarg(name: "name", opt: true, types: strL),
          Kwarg(
            name: "sources",
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ), Kwarg(name: "extra_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "method", opt: true, types: strL),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "compile_ui",
        parent: t,
        returnTypes: [ListType(types: [self.types["custom_tgt"]!])],
        args: [
          Kwarg(
            name: "sources",
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ), Kwarg(name: "extra_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "method", opt: true, types: strL),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "compile_moc",
        parent: t,
        returnTypes: [ListType(types: [self.types["custom_tgt"]!])],
        args: [
          Kwarg(
            name: "sources",
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ),
          Kwarg(
            name: "headers",
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ), Kwarg(name: "extra_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "method", opt: true, types: strL),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [self.types["dep"]!, self.types["lib"]!])]
          ),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [self.types["inc"]!, str])]
          ),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "preprocess",
        parent: t,
        returnTypes: [ListType(types: [self.types["custom_tgt"]!])],
        args: [
          PositionalArgument(name: "name", opt: true, types: strL),
          Kwarg(name: "sources", opt: true, types: [ListType(types: [str, self.types["file"]!])]),
          Kwarg(
            name: "qresources",
            opt: true,
            types: [ListType(types: [str, self.types["file"]!])]
          ),
          Kwarg(
            name: "ui_files",
            opt: true,
            types: [ListType(types: [str, self.types["file"]!, self.types["custom_tgt"]!])]
          ),
          Kwarg(
            name: "moc_sources",
            opt: true,
            types: [ListType(types: [str, self.types["file"]!, self.types["custom_tgt"]!])]
          ),
          Kwarg(
            name: "moc_headers",
            opt: true,
            types: [ListType(types: [str, self.types["file"]!, self.types["custom_tgt"]!])]
          ), Kwarg(name: "moc_extra_arguments", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "rcc_extra_arguments", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "uic_extra_arguments", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "method", opt: true, types: strL),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [self.types["dep"]!, self.types["lib"]!])]
          ),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [self.types["inc"]!, str])]
          ),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "compile_translations",
        parent: t,
        returnTypes: [ListType(types: [self.types["custom_tgt"]!])],
        args: [
          Kwarg(name: "build_by_default", opt: true, types: boolL),
          Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(
            name: "ts_files",
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ), Kwarg(name: "rcc_extra_arguments", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "method", opt: true, types: strL),
          Kwarg(name: "qresource", opt: true, types: strL),
        ]
      ),
      Method(
        name: "has_tools",
        parent: t,
        returnTypes: boolL,
        args: [
          Kwarg(name: "required", opt: true, types: boolL),
          Kwarg(name: "method", opt: true, types: strL),
        ]
      ),
    ]
    t = self.types["qt6_module"]!
    self.vtables["qt6_module"] = [
      Method(
        name: "compile_resources",
        parent: t,
        returnTypes: [ListType(types: [self.types["custom_tgt"]!])],
        args: [
          Kwarg(name: "name", opt: true, types: strL),
          Kwarg(
            name: "sources",
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ), Kwarg(name: "extra_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "method", opt: true, types: strL),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "compile_ui",
        parent: t,
        returnTypes: [ListType(types: [self.types["custom_tgt"]!])],
        args: [
          Kwarg(
            name: "sources",
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ), Kwarg(name: "extra_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "method", opt: true, types: strL),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "compile_moc",
        parent: t,
        returnTypes: [ListType(types: [self.types["custom_tgt"]!])],
        args: [
          Kwarg(
            name: "sources",
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ),
          Kwarg(
            name: "headers",
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ), Kwarg(name: "extra_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "method", opt: true, types: strL),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [self.types["dep"]!, self.types["lib"]!])]
          ),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [self.types["inc"]!, str])]
          ),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "preprocess",
        parent: t,
        returnTypes: [ListType(types: [self.types["custom_tgt"]!])],
        args: [
          PositionalArgument(name: "name", opt: true, types: strL),
          Kwarg(name: "sources", opt: true, types: [ListType(types: [str, self.types["file"]!])]),
          Kwarg(
            name: "qresources",
            opt: true,
            types: [ListType(types: [str, self.types["file"]!])]
          ),
          Kwarg(
            name: "ui_files",
            opt: true,
            types: [ListType(types: [str, self.types["file"]!, self.types["custom_tgt"]!])]
          ),
          Kwarg(
            name: "moc_sources",
            opt: true,
            types: [ListType(types: [str, self.types["file"]!, self.types["custom_tgt"]!])]
          ),
          Kwarg(
            name: "moc_headers",
            opt: true,
            types: [ListType(types: [str, self.types["file"]!, self.types["custom_tgt"]!])]
          ), Kwarg(name: "moc_extra_arguments", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "rcc_extra_arguments", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "uic_extra_arguments", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "method", opt: true, types: strL),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [self.types["dep"]!, self.types["lib"]!])]
          ),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [self.types["inc"]!, str])]
          ),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "compile_translations",
        parent: t,
        returnTypes: [ListType(types: [self.types["custom_tgt"]!])],
        args: [
          Kwarg(name: "build_by_default", opt: true, types: boolL),
          Kwarg(name: "install", opt: true, types: boolL),
          Kwarg(name: "install_dir", opt: true, types: strL),
          Kwarg(
            name: "ts_files",
            opt: true,
            types: [
              str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!,
              self.types["generated_list"]!,
            ]
          ), Kwarg(name: "rcc_extra_arguments", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "method", opt: true, types: strL),
          Kwarg(name: "qresource", opt: true, types: strL),
        ]
      ),
      Method(
        name: "has_tools",
        parent: t,
        returnTypes: boolL,
        args: [
          Kwarg(name: "required", opt: true, types: boolL),
          Kwarg(name: "method", opt: true, types: strL),
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
          PositionalArgument(name: "name", types: strL),
          PositionalArgument(name: "tgt", types: [self.types["build_tgt"]!]),
          Kwarg(
            name: "args",
            opt: true,
            types: [ListType(types: [str, self.types["file"]!, self.types["tgt"]!])]
          ),
          Kwarg(
            name: "depends",
            opt: true,
            types: [ListType(types: [self.types["build_tgt"]!, self.types["custom_tgt"]!])]
          ), Kwarg(name: "env", opt: true, types: [str, ListType(types: strL), Dict(types: strL)]),
          Kwarg(name: "is_parallel", opt: true, types: boolL),
          Kwarg(name: "priority", opt: true, types: inttL),
          Kwarg(name: "should_fail", opt: true, types: boolL),
          Kwarg(name: "suite", opt: true, types: [str, ListType(types: strL)]),
          Kwarg(name: "timeout", opt: true, types: inttL),
          Kwarg(name: "verbose", opt: true, types: boolL),
          Kwarg(name: "workdir", opt: true, types: strL),
        ]
      ),
      Method(
        name: "bindgen",
        parent: t,
        returnTypes: [self.types["custom_tgt"]!],
        args: [
          Kwarg(name: "c_args", opt: true, types: [ListType(types: strL)]),
          Kwarg(name: "args", opt: true, types: [ListType(types: strL)]),
          Kwarg(
            name: "input",
            opt: true,
            types: [
              ListType(types: [
                self.types["file"]!, self.types["generated_list"]!, self.types["build_tgt"]!,
                self.types["extracted_obj"]!, self.types["custom_idx"]!, self.types["custom_tgt"]!,
                str,
              ])
            ]
          ),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [str, self.types["inc"]!])]
          ), Kwarg(name: "output", types: strL),
          Kwarg(
            name: "dependencies",
            opt: true,
            types: [ListType(types: [self.types["build_tgt"]!, self.types["custom_tgt"]!])]
          ),
        ]
      ),
    ]
    t = self.types["simd_module"]!
    self.vtables["simd_module"] = [
      Method(
        name: "check",
        parent: t,
        returnTypes: [ListType(types: [self.types["cfg_data"]!, self.types["lib"]!])],
        args: [
          PositionalArgument(name: "name", types: strL),
          Kwarg(name: "compiler", opt: true, types: [self.types["compiler"]!]),
          Kwarg(
            name: "mmx",
            opt: true,
            types: [str, self.types["file"]!, ListType(types: [str, self.types["file"]!])]
          ),
          Kwarg(
            name: "sse",
            opt: true,
            types: [str, self.types["file"]!, ListType(types: [str, self.types["file"]!])]
          ),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [str, self.types["inc"]!])]
          ),
          Kwarg(
            name: "sse2",
            opt: true,
            types: [str, self.types["file"]!, ListType(types: [str, self.types["file"]!])]
          ),
          Kwarg(
            name: "sse3",
            opt: true,
            types: [str, self.types["file"]!, ListType(types: [str, self.types["file"]!])]
          ),
          Kwarg(
            name: "ssse3",
            opt: true,
            types: [str, self.types["file"]!, ListType(types: [str, self.types["file"]!])]
          ),
          Kwarg(
            name: "sse41",
            opt: true,
            types: [str, self.types["file"]!, ListType(types: [str, self.types["file"]!])]
          ),
          Kwarg(
            name: "sse42",
            opt: true,
            types: [str, self.types["file"]!, ListType(types: [str, self.types["file"]!])]
          ),
          Kwarg(
            name: "avx",
            opt: true,
            types: [str, self.types["file"]!, ListType(types: [str, self.types["file"]!])]
          ),
          Kwarg(
            name: "avx2",
            opt: true,
            types: [str, self.types["file"]!, ListType(types: [str, self.types["file"]!])]
          ),
          Kwarg(
            name: "neon",
            opt: true,
            types: [str, self.types["file"]!, ListType(types: [str, self.types["file"]!])]
          ), Kwarg(name: "dependencies", opt: true, types: [ListType(types: [self.types["dep"]!])]),
        ]
      )
    ]
    t = self.types["sourcefiles"]!
    self.vtables["sourcefiles"] = [
      Method(
        name: "sources",
        parent: t,
        returnTypes: [ListType(types: [str, self.types["file"]!])],
        args: []
      ),
      Method(
        name: "dependencies",
        parent: t,
        returnTypes: [ListType(types: [str, self.types["file"]!])],
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
            types: [
              str, self.types["file"]!, self.types["generated_list"]!, self.types["custom_tgt"]!,
              self.types["custom_idx"]!,
            ]
          ), Kwarg(name: "when", opt: true, types: [ListType(types: [self.types["dep"]!])]),
          Kwarg(
            name: "if_true",
            opt: true,
            types: [
              ListType(types: [
                str, self.types["file"]!, self.types["generated_list"]!, self.types["custom_tgt"]!,
                self.types["custom_idx"]!, self.types["dep"]!,
              ])
            ]
          ),
          Kwarg(
            name: "if_false",
            opt: true,
            types: [
              ListType(types: [
                str, self.types["file"]!, self.types["generated_list"]!, self.types["custom_tgt"]!,
                self.types["custom_idx"]!, self.types["dep"]!,
              ])
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
          Kwarg(name: "when", opt: true, types: [ListType(types: [self.types["dep"]!])]),
          Kwarg(name: "if_true", opt: true, types: [ListType(types: [t])]),
        ]
      ),
      Method(
        name: "all_sources",
        parent: t,
        returnTypes: [ListType(types: [str, self.types["file"]!])],
        args: []
      ),
      Method(
        name: "all_dependencies",
        parent: t,
        returnTypes: [ListType(types: [str, self.types["file"]!])],
        args: []
      ),
      Method(
        name: "apply",
        parent: t,
        returnTypes: [self.types["sourcefiles"]!],
        args: [
          PositionalArgument(name: "cfg", types: [self.types["cfg_data"]!, Dict(types: strL)]),
          Kwarg(name: "strict", opt: true, types: boolL),
        ]
      ),
    ]
    t = self.types["sourceset_module"]!
    self.vtables["sourceset_module"] = [
      Method(name: "source_set", parent: t, returnTypes: [self.types["sourceset"]!], args: [])
    ]
    t = self.types["wayland_module"]!
    self.vtables["wayland_module"] = [
      Method(
        name: "scan_xml",
        parent: t,
        returnTypes: [ListType(types: [self.types["custom_tgt"]!])],
        args: [
          PositionalArgument(name: "files", varargs: true, types: [str, self.types["file"]!]),
          Kwarg(name: "public", opt: true, types: boolL),
          Kwarg(name: "client", opt: true, types: boolL),
          Kwarg(name: "server", opt: true, types: boolL),
          Kwarg(name: "include_core_only", opt: true, types: boolL),
        ]
      ),
      Method(
        name: "find_protocol",
        parent: t,
        returnTypes: [self.types["file"]!],
        args: [
          PositionalArgument(name: "files", types: strL),
          Kwarg(name: "state", opt: true, types: strL),
          Kwarg(name: "version", opt: true, types: inttL),
        ]
      ),
    ]
    t = self.types["windows_module"]!
    self.vtables["windows_module"] = [
      Method(
        name: "compile_resources",
        parent: t,
        returnTypes: [self.types["external_program"]!],
        args: [
          PositionalArgument(
            name: "libs",
            varargs: true,
            types: [str, self.types["file"]!, self.types["custom_tgt"]!, self.types["custom_idx"]!]
          ),
          Kwarg(
            name: "depends",
            opt: true,
            types: [ListType(types: [self.types["build_tgt"]!, self.types["custom_tgt"]!])]
          ),
          Kwarg(
            name: "depend_files",
            opt: true,
            types: [ListType(types: [str, self.types["file"]!])]
          ),
          Kwarg(
            name: "include_directories",
            opt: true,
            types: [ListType(types: [str, self.types["inc"]!])]
          ), Kwarg(name: "args", opt: true, types: [str, ListType(types: strL)]),
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
