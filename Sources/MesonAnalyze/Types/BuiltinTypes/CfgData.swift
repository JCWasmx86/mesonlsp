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
        ],
        args: [
          PositionalArgument(
            name: "varname",
            types: [
              Str()
            ]),
          PositionalArgument(
            name: "default_value", opt: true,
            types: [
              Str(),
              `IntType`(),
              BoolType(),
            ]),
        ]),
      Method(
        name: "get_unquoted", parent: self,
        returnTypes: [
          BoolType(),
          Str(),
          `IntType`(),
        ],
        args: [
          PositionalArgument(
            name: "varname",
            types: [
              Str()
            ]),
          PositionalArgument(
            name: "default_value", opt: true,
            types: [
              Str(),
              `IntType`(),
              BoolType(),
            ]),
        ]),
      Method(
        name: "has", parent: self,
        returnTypes: [
          BoolType()
        ],
        args: [
          PositionalArgument(
            name: "varname",
            types: [
              Str()
            ])
        ]),
      Method(
        name: "keys", parent: self,
        returnTypes: [
          ListType(types: [Str()])
        ]),
      Method(
        name: "merge_from", parent: self,
        args: [
          PositionalArgument(
            name: "other",
            types: [
              self
            ])
        ]),
      Method(
        name: "set", parent: self,
        args: [
          PositionalArgument(
            name: "varname",
            types: [
              Str()
            ]),
          PositionalArgument(
            name: "value",
            types: [
              Str(),
              `IntType`(),
              BoolType(),
            ]),
          Kwarg(
            name: "varname", opt: true,
            types: [
              `IntType`(),
              BoolType(),
            ]),
        ]),
      Method(
        name: "set10", parent: self,
        args: [
          PositionalArgument(
            name: "varname",
            types: [
              Str()
            ]),
          PositionalArgument(
            name: "value",
            types: [
              Str(),
              `IntType`(),
              BoolType(),
            ]),
          Kwarg(
            name: "varname", opt: true,
            types: [
              `IntType`(),
              BoolType(),
            ]),
        ]),
      Method(
        name: "set_quoted", parent: self,
        args: [
          PositionalArgument(
            name: "varname",
            types: [
              Str()
            ]),
          PositionalArgument(
            name: "value",
            types: [
              Str(),
              `IntType`(),
              BoolType(),
            ]),
          Kwarg(
            name: "varname", opt: true,
            types: [
              `IntType`(),
              BoolType(),
            ]),
        ]),
    ]
  }
}
