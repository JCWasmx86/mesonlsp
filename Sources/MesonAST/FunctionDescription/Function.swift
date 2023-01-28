public class Function {
  public let name: String
  public let returnTypes: [Type]
  public let args: [Argument]
  var kwargs: [String: Kwarg] = [:]

  public init(name: String, returnTypes: [Type] = [`Void`()], args: [Argument] = []) {
    self.name = name
    self.args = args
    self.returnTypes = returnTypes
    for a in self.args { if let b = a as? Kwarg { kwargs[b.name] = b } }
  }
  public func id() -> String { return self.name }

  public func minPosArgs() -> Int {
    var x = 0
    for arg in args {
      if let pa = arg as? PositionalArgument { if pa.opt { return x } else { x += 1 } }
    }
    return x
  }

  public func hasKwarg(name: String) -> Bool { return self.kwargs[name] != nil }

  public func requiredKwargs() -> [String] {
    return Array(self.kwargs.values.filter({ !$0.opt }).map({ $0.name }))
  }
}
