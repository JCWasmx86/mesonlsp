public class Dep: AbstractObject {
  public let name: String = "dep"
  public var methods: [Method] = []
  public let parent: AbstractObject? = nil

  public init() {
    self.methods = [
      Method(
        name: "as_link_whole", parent: self,
        returnTypes: [
          self
        ]),
      Method(
        name: "as_system", parent: self,
        returnTypes: [
          self
        ]),
      Method(
        name: "found", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "get_configtool_variable", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "get_pkgconfig_variable", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "get_variable", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "include_type", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "name", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "partial_dependency", parent: self,
        returnTypes: [
          self
        ]),
      Method(
        name: "type_name", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "version", parent: self,
        returnTypes: [
          Str()
        ]),
    ]
  }
}
