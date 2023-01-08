public class Feature: AbstractObject {
  public let name: String = "feature"
  public var methods: [Method] = []
  public let parent: AbstractObject? = nil

  public init() {}
}
