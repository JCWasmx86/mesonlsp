public struct SourceSet: AbstractObject {
  public let name: String = "sourceset"
  public let parent: AbstractObject? = nil
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "add",
        parent: self,
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
        parent: self,
        returnTypes: [],
        args: [
          PositionalArgument(name: "sources", varargs: true, opt: true, types: [self]),
          Kwarg(name: "when", opt: true, types: [ListType(types: [Dep()])]),
          Kwarg(name: "if_true", opt: true, types: [ListType(types: [self])]),
        ]
      ),
      Method(
        name: "all_sources",
        parent: self,
        returnTypes: [ListType(types: [Str(), File()])],
        args: []
      ),
      Method(
        name: "all_dependencies",
        parent: self,
        returnTypes: [ListType(types: [Str(), File()])],
        args: []
      ),
      Method(
        name: "apply",
        parent: self,
        returnTypes: [SourceFiles()],
        args: [
          PositionalArgument(name: "cfg", types: [CfgData(), Dict(types: [Str()])]),
          Kwarg(name: "strict", opt: true, types: [BoolType()]),
        ]
      ),
    ]
  }
}
