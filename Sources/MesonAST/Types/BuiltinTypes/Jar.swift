public struct Jar: AbstractObject {
  public let name: String = "jar"
  public var methods: [Method] = []
  public let parent: AbstractObject? = BuildTgt()

  public init() {}
}
