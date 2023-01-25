public struct CudaModule: AbstractObject {
  public let name: String = "cuda_module"
  public let parent: AbstractObject? = Module()
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "min_driver_version", parent: self, returnTypes: [Str()],
        args: [PositionalArgument(name: "version_string", types: [Str()])]),
      Method(
        name: "nvcc_arch_flags", parent: self, returnTypes: [ListType(types: [Str()])],
        args: [
          PositionalArgument(name: "architecture_set", opt: true, types: [Str()]),
          Kwarg(name: "detected", opt: true, types: [Str(), ListType(types: [Str()])]),
        ]),
      Method(
        name: "nvcc_arch_readable", parent: self, returnTypes: [ListType(types: [Str()])],
        args: [
          PositionalArgument(name: "architecture_set", opt: true, types: [Str()]),
          Kwarg(name: "detected", opt: true, types: [Str(), ListType(types: [Str()])]),
        ]),
    ]
  }
}
