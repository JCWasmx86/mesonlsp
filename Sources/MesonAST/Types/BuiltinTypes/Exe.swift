public struct Exe: AbstractObject {
  public let name: String = "exe"
  public let parent: AbstractObject? = BuildTgt()

  public init() {}
}
