public struct `Any`: Type {
  public let name: String = "any"
  public var methods: [Method] = []
  public init() {}

  public func toString() -> String { return "any" }
}
