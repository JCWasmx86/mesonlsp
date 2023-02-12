public struct ListType: Type {
  public let name: String = "list"
  public var types: [Type]

  public init(types: [Type]) { self.types = types }

  public func toString() -> String {
    return "list(" + self.types.map { $0.toString() }.joined(separator: "|") + ")"
  }
}
