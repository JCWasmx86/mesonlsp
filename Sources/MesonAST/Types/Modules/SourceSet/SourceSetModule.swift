public struct SourcesetModule: AbstractObject {
  public let name: String = "sourceset_module"
  public let parent: AbstractObject? = Module()
  public var methods: [Method] = []

  public init() {
    self.methods = [Method(name: "source_set", parent: self, returnTypes: [SourceSet()], args: [])]
  }
}
