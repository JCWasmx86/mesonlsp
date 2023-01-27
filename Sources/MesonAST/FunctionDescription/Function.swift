public class Function {
  public let name: String
  public let returnTypes: [Type]
  public let args: [Argument]

  public init(name: String, returnTypes: [Type] = [`Void`()], args: [Argument] = []) {
    self.name = name
    self.args = args
    self.returnTypes = returnTypes
  }
  public func id() -> String { return self.name }

  public func minPosArgs() -> Int {
    var x = 0
    for arg in args {
      if let pa = arg as? PositionalArgument { if pa.opt { return x } else { x += 1 } }
    }
    return x
  }
}
