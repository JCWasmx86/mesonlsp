public struct I18nModule: AbstractObject {
  public let name: String = "i18n_module"
  public let parent: AbstractObject? = Module()
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "gettext", parent: self,
        returnTypes: [ListType(types: [ListType(types: [CustomTgt()]), RunTgt()])],
        args: [
          PositionalArgument(name: "packagename", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "data_dirs", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "preset", opt: true, types: [Str()]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
        ]),
      Method(
        name: "merge_file", parent: self, returnTypes: [CustomTgt()],
        args: [
          Kwarg(name: "output", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "data_dirs", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "po_dir", types: [Str()]), Kwarg(name: "type", opt: true, types: [Str()]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_tag", opt: true, types: [Str()]),
          Kwarg(
            name: "input", opt: true,
            types: [
              ListType(types: [
                Str(), File(), ExternalProgram(), BuildTgt(), CustomTgt(), CustomIdx(),
                ExtractedObj(), GeneratedList(),
              ])
            ]),
        ]),
      Method(
        name: "itstool_join", parent: self, returnTypes: [CustomTgt()],
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
            name: "input", opt: true,
            types: [
              ListType(types: [
                Str(), File(), ExternalProgram(), BuildTgt(), CustomTgt(), CustomIdx(),
                ExtractedObj(), GeneratedList(),
              ])
            ]),
        ]),
    ]
  }
}
