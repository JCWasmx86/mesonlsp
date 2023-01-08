public class Subproject: AbstractObject {
  public let name: String = "subproject"
  public var methods: [Method] = []
  public let parent: AbstractObject? = nil

  public init() {}
}
