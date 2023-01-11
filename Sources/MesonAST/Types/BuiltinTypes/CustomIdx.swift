public class CustomIdx: AbstractObject {
  public let name: String = "custom_idx"
  public var methods: [Method] = []
  public let parent: AbstractObject? = nil

  public init() { self.methods = [Method(name: "full_path", parent: self, returnTypes: [Str()])] }
}
