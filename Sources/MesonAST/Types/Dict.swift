public final class Dict: Type {
  public let name: String = "dict"
  public let types: [Type]
  private let cache: String

  public init(types: [Type]) {
    self.types = types
    self.cache = "dict(" + self.types.map { $0.toString() }.sorted().joined(separator: "|") + ")"
  }
  public func toString() -> String { return self.cache }
}
