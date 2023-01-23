public struct HotdocModule: AbstractObject {
  public let name: String = "hotdoc_module"
  public let parent: AbstractObject? = Module()
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "has_extensions", parent: self, returnTypes: [BoolType()],
        args: [PositionalArgument(name: "extensions", varargs: true, types: [Str()])]),
      Method(
        name: "generate_doc", parent: self, returnTypes: [HotdocTarget()],
        args: [
          PositionalArgument(name: "project_name", types: [Str()]),
          Kwarg(name: "sitemap", types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "index", types: [Str(), File(), CustomTgt(), CustomIdx()]),
          Kwarg(name: "project_version", types: [Str()]),
          Kwarg(
            name: "html_extra_theme", opt: true,
            types: [

            ]), Kwarg(name: "include_paths", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(
            name: "dependencies", opt: true,
            types: [ListType(types: [Str(), Lib(), CustomTgt(), CustomIdx()])]),
          Kwarg(name: "depends", opt: true, types: [ListType(types: [CustomTgt(), CustomIdx()])]),
          Kwarg(name: "gi_c_source_roots", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "extra_assets", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "extra_extension_paths", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "subprojects", opt: true, types: [ListType(types: [HotdocTarget()])]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
        ]),
    ]
  }
}
