public class File: AbstractObject {
  public let name: String = "file"
  public var methods: [Method] = []
  public let parent: AbstractObject? = nil

  public init() {}
}
