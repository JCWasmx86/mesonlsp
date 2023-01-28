public struct Compiler: AbstractObject {
  public let name: String = "compiler"
  public var methods: [Method] = []
  public let parent: AbstractObject? = nil

  public init() {
    self.methods = [
      Method(
        name: "alignment", parent: self, returnTypes: [`IntType`()],
        args: [
          PositionalArgument(name: "typename", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: [Str()]), Str()]),
        ]),
      Method(
        name: "check_header", parent: self, returnTypes: [BoolType()],
        args: [
          PositionalArgument(name: "header_name", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: [Str()]), Str()]),
          Kwarg(name: "required", opt: true, types: [BoolType(), Feature()]),
        ]), Method(name: "cmd_array", parent: self, returnTypes: [ListType(types: [Str()])]),
      Method(
        name: "compiles", parent: self, returnTypes: [BoolType()],
        args: [
          PositionalArgument(name: "code", types: [Str(), File()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "name", opt: true, types: [Str()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
        ]),
      Method(
        name: "compute_int", parent: self, returnTypes: [`IntType`()],
        args: [
          PositionalArgument(name: "expr", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "guess", opt: true, types: [`IntType`()]),
          Kwarg(name: "high", opt: true, types: [`IntType`()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "low", opt: true, types: [`IntType`()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: [Str()]), Str()]),
        ]),
      Method(
        name: "find_library", parent: self, returnTypes: [Dep()],
        args: [
          PositionalArgument(name: "libname", types: [Str()]),
          Kwarg(name: "dirs", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "disabler", opt: true, types: [BoolType()]),
          Kwarg(name: "header_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "header_dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(
            name: "header_include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "header_no_builtin_args", opt: true, types: [BoolType()]),
          Kwarg(name: "header_prefix", opt: true, types: [Str()]),
          Kwarg(name: "required", opt: true, types: [BoolType(), Feature()]),
          Kwarg(name: "static", opt: true, types: [Str()]),
        ]),
      Method(
        name: "first_supported_argument", parent: self, returnTypes: [ListType(types: [Str()])],
        args: [PositionalArgument(name: "arg", varargs: true, opt: true, types: [Str()])]),
      Method(
        name: "first_supported_link_argument", parent: self,
        returnTypes: [ListType(types: [Str()])],
        args: [PositionalArgument(name: "arg", varargs: true, opt: true, types: [Str()])]),
      Method(name: "get_argument_syntax", parent: self, returnTypes: [Str()]),
      Method(
        name: "get_define", parent: self, returnTypes: [Str()],
        args: [
          PositionalArgument(name: "definename", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: [Str()]), Str()]),
        ]), Method(name: "get_id", parent: self, returnTypes: [Str()]),
      Method(name: "get_linker_id", parent: self, returnTypes: [Str()]),
      Method(
        name: "get_supported_arguments", parent: self, returnTypes: [ListType(types: [Str()])],
        args: [
          PositionalArgument(name: "arg", varargs: true, opt: true, types: [Str()]),
          Kwarg(name: "checked", opt: true, types: [Str()]),
        ]),
      Method(
        name: "get_supported_function_attributes", parent: self,
        returnTypes: [ListType(types: [Str()])],
        args: [PositionalArgument(name: "attribs", varargs: true, opt: true, types: [Str()])]),
      Method(
        name: "get_supported_link_arguments", parent: self, returnTypes: [ListType(types: [Str()])],
        args: [PositionalArgument(name: "arg", varargs: true, opt: true, types: [Str()])]),
      Method(
        name: "has_argument", parent: self, returnTypes: [BoolType()],
        args: [PositionalArgument(name: "argument", types: [Str()])]),
      Method(
        name: "has_function", parent: self, returnTypes: [BoolType()],
        args: [
          PositionalArgument(name: "funcname", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: [Str()]), Str()]),
        ]),
      Method(
        name: "has_function_attribute", parent: self, returnTypes: [BoolType()],
        args: [PositionalArgument(name: "name", types: [Str()])]),
      Method(
        name: "has_header", parent: self, returnTypes: [BoolType()],
        args: [
          PositionalArgument(name: "header_name", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: [Str()]), Str()]),
          Kwarg(name: "required", opt: true, types: [BoolType(), Feature()]),
        ]),
      Method(
        name: "has_header_symbol", parent: self, returnTypes: [BoolType()],
        args: [
          PositionalArgument(name: "header", types: [Str()]),
          PositionalArgument(name: "symbol", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: [Str()]), Str()]),
          Kwarg(name: "required", opt: true, types: [BoolType(), Feature()]),
        ]),
      Method(
        name: "has_link_argument", parent: self, returnTypes: [BoolType()],
        args: [PositionalArgument(name: "argument", types: [Str()])]),
      Method(
        name: "has_member", parent: self, returnTypes: [BoolType()],
        args: [
          PositionalArgument(name: "typename", types: [Str()]),
          PositionalArgument(name: "membername", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: [Str()]), Str()]),
        ]),
      Method(
        name: "has_members", parent: self, returnTypes: [BoolType()],
        args: [
          PositionalArgument(name: "typename", types: [Str()]),
          PositionalArgument(name: "member", varargs: true, types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: [Str()]), Str()]),
        ]),
      Method(
        name: "has_multi_arguments", parent: self, returnTypes: [BoolType()],
        args: [PositionalArgument(name: "arg", varargs: true, opt: true, types: [Str()])]),
      Method(
        name: "has_multi_link_arguments", parent: self, returnTypes: [BoolType()],
        args: [PositionalArgument(name: "arg", varargs: true, opt: true, types: [Str()])]),
      Method(
        name: "has_type", parent: self, returnTypes: [BoolType()],
        args: [
          PositionalArgument(name: "typename", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: [Str()]), Str()]),
        ]),
      Method(
        name: "links", parent: self, returnTypes: [BoolType()],
        args: [
          PositionalArgument(name: "source", types: [Str(), File()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "name", opt: true, types: [Str()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
        ]),
      Method(
        name: "preprocess", parent: self, returnTypes: [ListType(types: [CustomIdx()])],
        args: [
          PositionalArgument(
            name: "source", varargs: true, opt: true,
            types: [Str(), File(), CustomTgt(), CustomIdx(), GeneratedList()]),
          Kwarg(name: "compile_args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "output", opt: true, types: [Str()]),
        ]),
      Method(
        name: "run", parent: self, returnTypes: [RunResult()],
        args: [
          PositionalArgument(name: "code", types: [Str(), File()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "name", opt: true, types: [Str()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
        ]),
      Method(
        name: "sizeof", parent: self, returnTypes: [`IntType`()],
        args: [
          PositionalArgument(name: "typename", types: [Str()]),
          Kwarg(name: "args", opt: true, types: [ListType(types: [Str()])]),
          Kwarg(name: "dependencies", opt: true, types: [ListType(types: [Dep()]), Dep()]),
          Kwarg(name: "include_directories", opt: true, types: [ListType(types: [Inc()]), Inc()]),
          Kwarg(name: "name", opt: true, types: [Str()]),
          Kwarg(name: "no_builtin_args", opt: true, types: [BoolType()]),
          Kwarg(name: "prefix", opt: true, types: [ListType(types: [Str()]), Str()]),
        ]), Method(name: "symbols_have_underscore_prefix", parent: self, returnTypes: [BoolType()]),
      Method(name: "version", parent: self, returnTypes: [Str()]),
    ]
  }
}
