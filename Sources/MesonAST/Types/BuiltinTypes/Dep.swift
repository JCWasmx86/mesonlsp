public struct Dep: AbstractObject {
  public let name: String = "dep"
  public var methods: [Method] = []
  public let parent: AbstractObject? = nil

  public init() {
    self.methods = [
      Method(name: "as_link_whole", parent: self, returnTypes: [self]),
      Method(
        name: "as_system",
        parent: self,
        returnTypes: [self],
        args: [PositionalArgument(name: "value", varargs: false, opt: true, types: [Str()])]
      ), Method(name: "found", parent: self, returnTypes: [BoolType()]),
      Method(
        name: "get_configtool_variable",
        parent: self,
        returnTypes: [Str()],
        args: [PositionalArgument(name: "var_name", types: [Str()])]
      ),
      Method(
        name: "get_pkgconfig_variable",
        parent: self,
        returnTypes: [Str()],
        args: [
          PositionalArgument(name: "var_name", types: [Str()]),
          Kwarg(name: "default", opt: true, types: [Str()]),
          Kwarg(name: "define_variable", opt: true, types: [ListType(types: [Str()])]),
        ]
      ),
      Method(
        name: "get_variable",
        parent: self,
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
      ), Method(name: "include_type", parent: self, returnTypes: [Str()]),
      Method(name: "name", parent: self, returnTypes: [Str()]),
      Method(
        name: "partial_dependency",
        parent: self,
        returnTypes: [self],
        args: [
          Kwarg(name: "compile_args", opt: true, types: [BoolType()]),
          Kwarg(name: "includes", opt: true, types: [BoolType()]),
          Kwarg(name: "link_args", opt: true, types: [BoolType()]),
          Kwarg(name: "links", opt: true, types: [BoolType()]),
          Kwarg(name: "sources", opt: true, types: [BoolType()]),
        ]
      ), Method(name: "type_name", parent: self, returnTypes: [Str()]),
      Method(name: "version", parent: self, returnTypes: [Str()]),
    ]
  }
}
