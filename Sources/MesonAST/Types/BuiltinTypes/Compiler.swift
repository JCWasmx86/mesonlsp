public class Compiler: AbstractObject {
  public let name: String = "compiler"
  public var methods: [Method] = []
  public let parent: AbstractObject? = nil

  public init() {
    self.methods = [
      Method(
        name: "alignment", parent: self,
        returnTypes: [
          `IntType`()
        ]),
      Method(
        name: "check_header", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "cmd_array", parent: self,
        returnTypes: [
          ListType(types: [Str()])
        ]),
      Method(
        name: "compiles", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "compute_int", parent: self,
        returnTypes: [
          `IntType`()
        ]),
      Method(
        name: "find_library", parent: self,
        returnTypes: [
          Dep()
        ]),
      Method(
        name: "first_supported_argument", parent: self,
        returnTypes: [
          ListType(types: [Str()])
        ]),
      Method(
        name: "first_supported_link_argument", parent: self,
        returnTypes: [
          ListType(types: [Str()])
        ]),
      Method(
        name: "get_argument_syntax", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "get_define", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "get_id", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "get_linker_id", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "get_supported_arguments", parent: self,
        returnTypes: [
          ListType(types: [Str()])
        ]),
      Method(
        name: "get_supported_function_attributes", parent: self,
        returnTypes: [
          ListType(types: [Str()])
        ]),
      Method(
        name: "get_supported_link_arguments", parent: self,
        returnTypes: [
          ListType(types: [Str()])
        ]),
      Method(
        name: "has_argument", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "has_function", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "has_function_attribute", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "has_header", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "has_header_symbol", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "has_link_argument", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "has_member", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "has_members", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "has_multi_arguments", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "has_multi_link_arguments", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "has_type", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "links", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "preprocess", parent: self,
        returnTypes: [
          ListType(types: [CustomIdx()])
        ]),
      Method(
        name: "run", parent: self,
        returnTypes: [
          RunResult()
        ]),
      Method(
        name: "sizeof", parent: self,
        returnTypes: [
          `IntType`()
        ]),
      Method(
        name: "symbols_have_underscore_prefix", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "version", parent: self,
        returnTypes: [
          BoolType()
        ]),
    ]
  }
}
