import MesonAST

public class Scope {
  public var variables: [String: [Type]] = [:]

  public init() {

  }

  public init(parent: Scope) {
    for v in parent.variables {
      self.variables[v.key] = v.value.compactMap { $0 }
    }
  }
}
