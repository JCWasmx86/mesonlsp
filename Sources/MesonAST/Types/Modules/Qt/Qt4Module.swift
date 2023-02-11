public struct Qt4Module: AbstractObject {
  public let name: String = "qt4_module"
  public let parent: AbstractObject? = Module()
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "compile_resources",
        parent: self,
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
        parent: self,
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
        parent: self,
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
        parent: self,
        returnTypes: [ListType(types: [CustomTgt()])],
        args: [
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
          ), Kwarg(name: "moc_extra_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "rcc_extra_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "uic_extra_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "method", opt: true, types: [Str()]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep(), Lib()])]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc(), Str()])]),
        ]
      ),
      // TODO: Return values?
      Method(
        name: "compile_translations",
        parent: self,
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
        parent: self,
        returnTypes: [BoolType()],
        args: [
          Kwarg(name: "required", opt: true, types: [BoolType()]),
          Kwarg(name: "method", opt: true, types: [Str()]),
        ]
      ),

    ]
  }
}
