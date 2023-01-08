public class RunTgt: AbstractObject {
  public let name: String = "run_tgt"
  public var methods: [Method] = []
  public let parent: AbstractObject? = Tgt()

  public init() {}
}
