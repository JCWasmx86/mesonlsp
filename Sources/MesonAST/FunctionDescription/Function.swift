public class Function: Equatable, Hashable {
  public let name: String
  public let returnTypes: [Type]
  public let args: [Argument]
  public private(set) var kwargs: [String: Kwarg] = [:]
  private let minPosArgs_: Int
  private let maxPosArgs_: Int
  private let requiredKwargs_: [String]

  public init(name: String, returnTypes: [Type] = [], args: [Argument] = []) {
    self.name = name
    self.args = args
    self.returnTypes = returnTypes
    for a in self.args { if let b = a as? Kwarg { kwargs[b.name] = b } }
    var x = 0
    for arg in args {
      if let pa = arg as? PositionalArgument { if pa.opt { break } else { x += 1 } }
    }
    self.minPosArgs_ = x
    x = 0
    for arg in args {
      if let pa = arg as? PositionalArgument {
        x += 1
        if pa.varargs {
          x = Int.max
          break
        }
      }
    }
    self.maxPosArgs_ = x
    self.requiredKwargs_ = Array(self.kwargs.values.filter { !$0.opt }.map { $0.name })
  }
  public func id() -> String { return self.name }

  public func minPosArgs() -> Int { return self.minPosArgs_ }

  public func maxPosArgs() -> Int { return self.maxPosArgs_ }

  public func hasKwarg(name: String) -> Bool { return self.kwargs[name] != nil }

  public func requiredKwargs() -> [String] { return self.requiredKwargs_ }

  public func hash(into hasher: inout Hasher) { hasher.combine("func" + self.name) }

  public static func == (lhs: Function, rhs: Function) -> Bool { return lhs.id() == rhs.id() }
}
