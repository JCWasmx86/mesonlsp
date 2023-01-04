public class PositionalArgument {
  public let name: String
  public let varargs: Bool
  public let opt: Bool

  public init(name: String, varargs: Bool, opt: Bool) {
    self.name = name
    self.varargs = varargs
    self.opt = opt
  }
}
