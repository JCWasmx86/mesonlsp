public class Env: AbstractObject {
  public let name: String = "env"
  public var methods: [Method] = []
  public let parent: AbstractObject? = nil

  public init() {
    self.methods = [
      Method(name: "append", parent: self),
      Method(name: "prepend", parent: self),
      Method(name: "set", parent: self),
    ]
  }
}
