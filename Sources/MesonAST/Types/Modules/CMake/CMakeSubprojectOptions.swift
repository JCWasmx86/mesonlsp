public class CMakeSubprojectOptions: AbstractObject {
  public let name: String = "cmake_subprojectoptions"
  public let parent: AbstractObject? = nil
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "add_cmake_defines",
        parent: self,
        returnTypes: [],
        args: [PositionalArgument(name: "defines", types: [Dict(types: [Str()])])]
      ),
      Method(
        name: "set_override_option",
        parent: self,
        returnTypes: [],
        args: [
          PositionalArgument(name: "opt", types: [Str()]),
          PositionalArgument(name: "val", types: [Str()]),
          Kwarg(name: "target", opt: true, types: [CMakeTarget()]),
        ]
      ),
      Method(
        name: "set_install",
        parent: self,
        returnTypes: [],
        args: [
          PositionalArgument(name: "install", types: [BoolType()]),
          Kwarg(name: "target", opt: true, types: [CMakeTarget()]),
        ]
      ),
      Method(
        name: "append_compile_args",
        parent: self,
        returnTypes: [],
        args: [
          PositionalArgument(name: "language", types: [Str()]),
          PositionalArgument(name: "arg", varargs: true, types: [Str()]),
          Kwarg(name: "target", opt: true, types: [CMakeTarget()]),
        ]
      ),
      Method(
        name: "append_link_args",
        parent: self,
        returnTypes: [],
        args: [
          PositionalArgument(name: "language", types: [Str()]),
          PositionalArgument(name: "arg", varargs: true, types: [Str()]),
          Kwarg(name: "target", opt: true, types: [CMakeTarget()]),
        ]
      ), Method(name: "clear", parent: self, returnTypes: [], args: []),
    ]
  }
}
