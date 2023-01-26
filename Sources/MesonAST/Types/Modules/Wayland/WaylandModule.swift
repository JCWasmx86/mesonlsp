public struct WaylandModule: AbstractObject {
  public let name: String = "wayland_module"
  public let parent: AbstractObject? = Module()
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "scan_xml", parent: self, returnTypes: [ListType(types: [CustomTgt()])],
        args: [
          PositionalArgument(name: "files", varargs: true, types: [Str(), File()]),
          Kwarg(name: "public", opt: true, types: [BoolType()]),
          Kwarg(name: "client", opt: true, types: [BoolType()]),
          Kwarg(name: "server", opt: true, types: [BoolType()]),
          Kwarg(name: "include_core_only", opt: true, types: [BoolType()]),
        ]),
      Method(
        name: "find_protocol", parent: self, returnTypes: [File()],
        args: [
          PositionalArgument(name: "files", types: [Str()]),
          Kwarg(name: "state", opt: true, types: [Str()]),
          Kwarg(name: "version", opt: true, types: [`IntType`()]),
        ]),
    ]
  }
}
