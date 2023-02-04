public struct LazyType: Type {
  public let name: String
  public var methods: [Method]

  public init(name: String) {
    self.name = name
    self.methods = []
  }

  public func toString() -> String { return self.name }
}
