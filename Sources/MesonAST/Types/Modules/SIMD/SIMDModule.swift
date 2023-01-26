public struct SIMDModule: AbstractObject {
  public let name: String = "simd_module"
  public let parent: AbstractObject? = Module()
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "check", parent: self, returnTypes: [ListType(types: [CfgData(), Lib()])],
        args: [
          PositionalArgument(name: "name", types: [Str()]),
          Kwarg(name: "compiler", opt: true, types: [Compiler()]),
          Kwarg(name: "mmx", opt: true, types: [Str(), File(), ListType(types: [Str(), File()])]),
          Kwarg(name: "sse", opt: true, types: [Str(), File(), ListType(types: [Str(), File()])]),
          Kwarg(
            name: "sse2", opt: true, types: [Str(), File(), ListType(types: [Str(), File()])]),
          Kwarg(
            name: "sse3", opt: true, types: [Str(), File(), ListType(types: [Str(), File()])]),
          Kwarg(
            name: "ssse3", opt: true, types: [Str(), File(), ListType(types: [Str(), File()])]),
          Kwarg(
            name: "sse41", opt: true, types: [Str(), File(), ListType(types: [Str(), File()])]),
          Kwarg(
            name: "sse42", opt: true, types: [Str(), File(), ListType(types: [Str(), File()])]),
          Kwarg(name: "avx", opt: true, types: [Str(), File(), ListType(types: [Str(), File()])]),
          Kwarg(
            name: "avx2", opt: true, types: [Str(), File(), ListType(types: [Str(), File()])]),
          Kwarg(
            name: "neon", opt: true, types: [Str(), File(), ListType(types: [Str(), File()])]),
        ])
    ]
  }
}
