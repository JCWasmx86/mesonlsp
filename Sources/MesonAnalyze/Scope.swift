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

  public func merge(other: Scope) {
    var keysToAdd: [String] = []
    for o in other.variables {
      var added = false
      for s in self.variables {
        if s.key == o.key {
          self.variables[s.key] = dedup(types: s.value + o.value)
          added = true
          break
        }
      }
      if !added {
        keysToAdd.append(o.key)
      }
    }
    for k in keysToAdd {
      self.variables[k] = other.variables[k]
    }
  }
}
