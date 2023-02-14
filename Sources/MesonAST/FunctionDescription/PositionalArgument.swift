public final class PositionalArgument: Argument {
  public let name: String
  public let varargs: Bool
  public let opt: Bool
  public var types: [Type]

  public init(name: String, varargs: Bool = false, opt: Bool = false, types: [Type]) {
    self.name = name
    self.varargs = varargs
    self.opt = opt
    self.types = types
  }
}
