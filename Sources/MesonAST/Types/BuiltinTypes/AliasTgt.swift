public struct AliasTgt: AbstractObject {
  public let name: String = "alias_tgt"
  public var methods: [Method] = []
  public let parent: AbstractObject? = Tgt()

  public init() {}
}
