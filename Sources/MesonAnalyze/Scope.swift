import Glibc
import MesonAST
import Timing

public class Scope {
  public var variables: [String: [Type]] = [:]

  public init() {

  }

  public init(parent: Scope) {
    for v in parent.variables { self.variables[v.key] = v.value.compactMap { $0 } }
  }

  public func merge(other: Scope) {
    let begin = clock()
    var keysToAdd: [String] = []
    for o in other.variables {
      var added = false
      for s in self.variables {
        if s.key == o.key {
          let begin1 = clock()
          self.variables[s.key] = dedup(types: s.value + o.value)
          Timing.INSTANCE.registerMeasurement(
            name: "mergeScope - dedup",
            begin: Int(begin1),
            end: Int(clock())
          )
          added = true
          break
        }
      }
      if !added { keysToAdd.append(o.key) }
    }
    for k in keysToAdd { self.variables[k] = other.variables[k] }
    Timing.INSTANCE.registerMeasurement(name: "mergeScope", begin: Int(begin), end: Int(clock()))
  }
}

func dedup(types: [Type]) -> [Type] {
  if types.count <= 0 { return types }
  var listtypes: [Type] = []
  var dicttypes: [Type] = []
  var hasAny: Bool = false
  var hasBool: Bool = false
  var hasInt: Bool = false
  var hasStr: Bool = false
  var objs: [String: Type] = [:]
  var gotList: Bool = false
  var gotDict: Bool = false
  for t in types {
    if t is `Any` { hasAny = true }
    if t is BoolType {
      hasBool = true
    } else if t is `IntType` {
      hasInt = true
    } else if t is Str {
      hasStr = true
    } else if t is Dict {
      dicttypes += (t as! Dict).types
      gotDict = true
    } else if t is ListType {
      listtypes += (t as! ListType).types
      gotList = true
    } else if t is `Void` {
      // Do nothing
    } else {
      objs[t.name] = t
    }
  }
  var ret: [Type] = []
  if listtypes.count != 0 || gotList { ret.append(ListType(types: dedup(types: listtypes))) }
  if dicttypes.count != 0 || gotDict { ret.append(Dict(types: dedup(types: dicttypes))) }
  if hasAny { ret.append(`Any`()) }
  if hasBool { ret.append(`BoolType`()) }
  if hasInt { ret.append(`IntType`()) }
  if hasStr { ret.append(Str()) }
  ret += objs.values
  return ret
}
