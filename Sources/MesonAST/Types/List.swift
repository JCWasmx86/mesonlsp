public final class ListType: Type {
  public let name: String = "list"
  public let types: [Type]
  private let cache: String

  public init(types: [Type]) {
    self.types = types
    self.cache = "list(" + self.types.map { $0.toString() }.sorted().joined(separator: "|") + ")"
  }

  public func toString() -> String { return self.cache }
}
