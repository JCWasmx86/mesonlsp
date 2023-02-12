public struct CustomTgt: AbstractObject {
  public let name: String = "custom_tgt"
  public let parent: AbstractObject? = Tgt()

  public init() {}
}
