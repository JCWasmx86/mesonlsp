public class CfgData: AbstractObject {
  public let name: String = "cfg_data"
  public var methods: [Method] = []
  public let parent: AbstractObject? = nil

  public init() {
    self.methods = [
      Method(
        name: "get", parent: self,
        returnTypes: [
          BoolType(),
          Str(),
          `IntType`(),
        ]),
      Method(
        name: "get_unquoted", parent: self,
        returnTypes: [
          BoolType(),
          Str(),
          `IntType`(),
        ]),
      Method(
        name: "has", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "keys", parent: self,
        returnTypes: [
          ListType(types: [Str()])
        ]),
      Method(name: "merge_from", parent: self),
      Method(name: "set", parent: self),
      Method(name: "set10", parent: self),
      Method(name: "set_quoted", parent: self),
    ]
  }
}
