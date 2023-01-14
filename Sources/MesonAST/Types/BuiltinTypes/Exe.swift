public struct Exe: AbstractObject {
  public let name: String = "exe"
  public var methods: [Method] = []
  public let parent: AbstractObject? = BuildTgt()

  public init() {}
}
