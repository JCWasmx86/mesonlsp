public class CMakeSubproject: AbstractObject {
  public let name: String = "cmake_subproject"
  public let parent: AbstractObject? = nil
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "dependency", parent: self, returnTypes: [Dep()],
        args: [
          PositionalArgument(name: "tgt", types: [CMakeTarget()]),
          Kwarg(name: "include_type", opt: true, types: [Str()]),
        ]),
      Method(
        name: "include_directories", parent: self, returnTypes: [Inc()],
        args: [PositionalArgument(name: "tgt", types: [CMakeTarget()])]),
      Method(
        name: "target", parent: self, returnTypes: [Tgt()],
        args: [PositionalArgument(name: "tgt", types: [CMakeTarget()])]),
      Method(
        name: "target_type", parent: self, returnTypes: [Str()],
        args: [PositionalArgument(name: "tgt", types: [CMakeTarget()])]),
      Method(name: "target_list", parent: self, returnTypes: [ListType(types: [Str()])], args: []),
      Method(name: "found", parent: self, returnTypes: [BoolType()]),
      Method(
        name: "get_variable", parent: self, returnTypes: [`Any`()],
        args: [
          PositionalArgument(name: "var_name", types: [Str()]),
          PositionalArgument(name: "fallback", opt: true, types: [`Any`()]),
        ]),
    ]
  }
}
