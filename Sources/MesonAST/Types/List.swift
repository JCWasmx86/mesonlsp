public final class ListType: Type {
  public let name: String = "list"
  public let types: [Type]

  public init(types: [Type]) { self.types = types }

  public func toString() -> String {
    return "list(" + self.types.map { $0.toString() }.sorted().joined(separator: "|") + ")"
  }
}
