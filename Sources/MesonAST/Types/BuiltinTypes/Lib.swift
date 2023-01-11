public class Lib: AbstractObject {
  public let name: String = "lib"
  public let parent: AbstractObject? = BuildTgt()
  public var methods: [Method] = []

  public init() { self.methods = [] }
}
