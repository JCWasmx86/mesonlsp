public class Env: AbstractObject {
  public let name: String = "env"
  public var methods: [Method] = []
  public let parent: AbstractObject? = nil

  public init() {}
}
