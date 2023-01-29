public struct Python3Module: AbstractObject {
  public let name: String = "python3_module"
  public let parent: AbstractObject? = Module()
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(name: "find_python", parent: self, returnTypes: [ExternalProgram()], args: []),
      Method(
        name: "extension_module",
        parent: self,
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
      ), Method(name: "language_version", parent: self, returnTypes: [Str()], args: []),
      Method(name: "sysconfig_path", parent: self, returnTypes: [Str()], args: []),
    ]
  }
}
