public struct HotdocTarget: AbstractObject {
  public let name: String = "hotdoc_target"
  public let parent: AbstractObject? = CustomTgt()
  public var methods: [Method] = []

  public init() { self.methods = [Method(name: "config_path", parent: self, returnTypes: [Str()])] }
}
