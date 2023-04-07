public final class Subproject: AbstractObject {
  public let name: String = "subproject"
  public let parent: AbstractObject? = nil
  public let names: [String]

  public init(names: [String]) { self.names = names }

  public func toString() -> String {
    return "subproject(" + self.names.sorted().joined(separator: "|") + ")"
  }
}
