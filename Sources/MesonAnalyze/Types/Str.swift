public class Str: Type {
  public let name: String = "str"
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "contains", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "endswith", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "format", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "join", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "replace", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "split", parent: self,
        returnTypes: [
          ListType(types: [Str()])
        ]),
      Method(
        name: "startswith", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "strip", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "substring", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "to_int", parent: self,
        returnTypes: [
          `IntType`()
        ]),
      Method(
        name: "to_lower", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "to_upper", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "underscorify", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "version_compare", parent: self,
        returnTypes: [
          BoolType()
        ]),
    ]
  }
}
