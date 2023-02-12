public class Dict: Type {
  public let name: String = "dict"
  public var types: [Type]

  public init(types: [Type]) { self.types = types }
  public func toString() -> String {
    return "dict(" + self.types.map { $0.toString() }.sorted().joined(separator: "|") + ")"
  }
}
