public class CustomTgt: AbstractObject {
  public let name: String = "compiler"
  public var methods: [Method] = []
  public let parent: AbstractObject? = Tgt()

  public init() {}
}
