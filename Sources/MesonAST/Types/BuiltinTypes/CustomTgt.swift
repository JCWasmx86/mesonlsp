public class CustomTgt: AbstractObject {
  public let name: String = "custom_tgt"
  public var methods: [Method] = []
  public let parent: AbstractObject? = Tgt()

  public init() {
    self.methods = [
      Method(name: "index", parent: self, returnTypes: [CustomIdx()]),
      Method(name: "full_path", parent: self, returnTypes: [Str()]),
      Method(name: "to_list", parent: self, returnTypes: [ListType(types: [CustomIdx()])]),
    ]
  }
}
