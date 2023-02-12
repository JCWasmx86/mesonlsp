public struct LazyType: Type {
  public let name: String

  public init(name: String) { self.name = name }

  public func toString() -> String { return self.name }
}
