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
          self
        ]),
      Method(
        name: "join", parent: self,
        returnTypes: [
          self
        ]),
      Method(
        name: "replace", parent: self,
        returnTypes: [
          self
        ]),
      Method(
        name: "split", parent: self,
        returnTypes: [
          ListType(types: [self])
        ]),
      Method(
        name: "startswith", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "strip", parent: self,
        returnTypes: [
          self
        ]),
      Method(
        name: "substring", parent: self,
        returnTypes: [
          self
        ]),
      Method(
        name: "to_int", parent: self,
        returnTypes: [
          `IntType`()
        ]),
      Method(
        name: "to_lower", parent: self,
        returnTypes: [
          self
        ]),
      Method(
        name: "to_upper", parent: self,
        returnTypes: [
          self
        ]),
      Method(
        name: "underscorify", parent: self,
        returnTypes: [
          self
        ]),
      Method(
        name: "version_compare", parent: self,
        returnTypes: [
          BoolType()
        ]),
    ]
  }
}
