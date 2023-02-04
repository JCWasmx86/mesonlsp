public class Kwarg: Argument {
  public let name: String
  public let opt: Bool
  public var types: [Type]

  public init(name: String, opt: Bool = false, types: [Type]) {
    self.name = name
    self.opt = opt
    self.types = types
  }
}
