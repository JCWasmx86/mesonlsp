public class Function {
  public let name: String
  public let returnTypes: [Type]
  public let args: [Argument]

  public init(name: String, returnTypes: [Type] = [`Void`()], args: [Argument] = []) {
    self.name = name
    self.args = args
    self.returnTypes = returnTypes
  }
}
