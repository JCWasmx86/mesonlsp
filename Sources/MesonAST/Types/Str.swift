public class Str: Type {
  public let name: String = "str"
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "contains", parent: self,
        returnTypes: [
          BoolType()
        ],
        args: [
          PositionalArgument(
            name: "fragment",
            types: [
              self
            ])
        ]),
      Method(
        name: "endswith", parent: self,
        returnTypes: [
          BoolType()
        ],
        args: [
          PositionalArgument(
            name: "fragment",
            types: [
              self
            ])
        ]),
      Method(
        name: "format", parent: self,
        returnTypes: [
          self
        ],
        args: [
          PositionalArgument(
            name: "fmt",
            types: [
              self
            ]),
          PositionalArgument(
            name: "value", varargs: true, opt: true,
            types: [
              `IntType`(),
              BoolType(),
              self,
            ]),
        ]),
      Method(
        name: "join", parent: self,
        returnTypes: [
          self
        ],
        args: [
          PositionalArgument(
            name: "strings", varargs: true, opt: true,
            types: [
              self
            ])
        ]),
      Method(
        name: "replace", parent: self,
        returnTypes: [
          self
        ],
        args: [
          PositionalArgument(
            name: "old",
            types: [
              self
            ]),
          PositionalArgument(
            name: "new",
            types: [
              self
            ]),
        ]),
      Method(
        name: "split", parent: self,
        returnTypes: [
          ListType(types: [self])
        ],
        args: [
          PositionalArgument(
            name: "split_string", opt: true,
            types: [
              self
            ])
        ]),
      Method(
        name: "startswith", parent: self,
        returnTypes: [
          BoolType()
        ],
        args: [
          PositionalArgument(
            name: "fragment",
            types: [
              self
            ])
        ]),
      Method(
        name: "strip", parent: self,
        returnTypes: [
          self
        ],
        args: [
          PositionalArgument(
            name: "strip_chars",
            opt: true,
            types: [
              self
            ])
        ]),
      Method(
        name: "substring", parent: self,
        returnTypes: [
          self
        ],
        args: [
          PositionalArgument(
            name: "start",
            opt: true,
            types: [
              `IntType`()
            ]),
          PositionalArgument(
            name: "end",
            opt: true,
            types: [
              `IntType`()
            ]),
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
        ],
        args: [
          PositionalArgument(
            name: "compare_string",
            types: [
              self
            ])
        ]),
    ]
  }
  public func toString() -> String {
    return "str"
  }
}
