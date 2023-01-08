public class Dep: AbstractObject {
  public let name: String = "dep"
  public var methods: [Method] = []
  public let parent: AbstractObject? = nil

  public init() {}
}
