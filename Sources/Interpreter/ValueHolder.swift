import MesonAST

open class ValueHolder {
  let type: Type

  public init(type: Type) { self.type = type }

  open func clone() -> ValueHolder { return ValueHolder(type: self.type) }

  open func equals(_ other: ValueHolder) -> Bool { return self.type.name == other.type.name }

  open func executeMethod(t: TypeNamespace, args: ArgsObject, name: String) -> ValueHolder? {
    return nil
  }
}

open class ErrorValueHolder: ValueHolder {
  public init(t: TypeNamespace) { super.init(type: t.types["void"]!) }
}

open class ListValueHolder: ValueHolder {
  public let values: [ValueHolder]

  public init(t: TypeNamespace, values: [ValueHolder]) {
    self.values = values
    super.init(type: t.types["list"]!)
  }

  init(t: Type, values: [ValueHolder]) {
    self.values = values
    super.init(type: t)
  }

  public override func clone() -> ValueHolder {
    return ListValueHolder(t: self.type, values: Array(self.values.map({ $0.clone() })))
  }

  public override func equals(_ other: ValueHolder) -> Bool {
    if let lh = other as? ListValueHolder {
      if lh.values.count != self.values.count { return false }
      for i in 0..<lh.values.count where !lh.values[i].equals(self.values[i]) { return false }
      return true
    }
    return false
  }
}

open class BoolValueHolder: ValueHolder {
  public let value: Bool

  public init(t: TypeNamespace, value: Bool) {
    self.value = value
    super.init(type: t.types["bool"]!)
  }

  init(t: Type, value: Bool) {
    self.value = value
    super.init(type: t)
  }

  public override func clone() -> ValueHolder {
    return BoolValueHolder(t: self.type, value: self.value)
  }

  public override func equals(_ other: ValueHolder) -> Bool {
    if let lh = other as? BoolValueHolder { return self.value == lh.value }
    return false
  }
}

open class StringValueHolder: ValueHolder {
  public let value: String

  public init(t: TypeNamespace, value: String) {
    self.value = value
    super.init(type: t.types["str"]!)
  }

  init(t: Type, value: String) {
    self.value = value
    super.init(type: t)
  }

  public override func clone() -> ValueHolder {
    return StringValueHolder(t: self.type, value: self.value)
  }

  public override func equals(_ other: ValueHolder) -> Bool {
    if let lh = other as? StringValueHolder { return self.value == lh.value }
    return false
  }

  public override func executeMethod(t: TypeNamespace, args: ArgsObject, name: String)
    -> ValueHolder?
  {
    switch name {
    case "strip":
      return StringValueHolder(
        t: t,
        value: self.value.trimmingCharacters(in: .whitespacesAndNewlines)
      )
    default: return nil
    }
  }
}

open class DictValueHolder: ValueHolder {
  public let values: [String: ValueHolder]

  public init(t: TypeNamespace, values: [String: ValueHolder]) {
    self.values = values
    super.init(type: t.types["dict"]!)
  }

  init(t: Type, values: [String: ValueHolder]) {
    self.values = values
    super.init(type: t)
  }

  public override func clone() -> ValueHolder {
    var copy: [String: ValueHolder] = [:]
    for m in self.values { copy[m.key] = m.value.clone() }
    return DictValueHolder(t: self.type, values: copy)
  }

  public override func equals(_ other: ValueHolder) -> Bool {
    if let lh = other as? DictValueHolder {
      if lh.values.count != self.values.count { return false }
      for k in lh.values.keys where self.values[k] == nil { return false }
      for k in self.values.keys where lh.values[k] == nil { return false }
      for k in self.values.keys where !lh.values[k]!.equals(self.values[k]!) { return false }
      return true
    }
    return false
  }
}

open class MesonValueHolder: ValueHolder {

  public init(t: TypeNamespace) { super.init(type: t.types["meson"]!) }
}

open class BuildMachineHolder: ValueHolder {

  public init(t: TypeNamespace) { super.init(type: t.types["build_machine"]!) }
}

open class HostMachineHolder: ValueHolder {

  public init(t: TypeNamespace) { super.init(type: t.types["host_machine"]!) }
}

open class TargetMachineHolder: ValueHolder {

  public init(t: TypeNamespace) { super.init(type: t.types["target_machine"]!) }
}

open class IntegerValueHolder: ValueHolder {
  public let value: Int

  public init(t: TypeNamespace, value: Int) {
    self.value = value
    super.init(type: t.types["int"]!)
  }

  init(t: Type, value: Int) {
    self.value = value
    super.init(type: t)
  }

  public override func clone() -> ValueHolder {
    return IntegerValueHolder(t: self.type, value: self.value)
  }

  public override func equals(_ other: ValueHolder) -> Bool {
    if let lh = other as? IntegerValueHolder { return self.value == lh.value }
    return false
  }
}

public class AliasTgtValueHolder: ValueHolder {
  public let name: String
  public let deps: [ValueHolder]

  public init(t: TypeNamespace, name: String, deps: [ValueHolder]) {
    self.name = name
    self.deps = deps
    super.init(type: t.types["alias_tgt"]!)
  }

  public init(t: Type, name: String, deps: [ValueHolder]) {
    self.name = name
    self.deps = deps
    super.init(type: t)
  }

  public override func clone() -> ValueHolder {
    return AliasTgtValueHolder(
      t: self.type,
      name: self.name,
      deps: Array(self.deps.map({ $0.clone() }))
    )
  }

  public override func equals(_ other: ValueHolder) -> Bool {
    if let lh = other as? AliasTgtValueHolder {
      if lh.deps.count != self.deps.count { return false }
      for i in 0..<lh.deps.count where !lh.deps[i].equals(self.deps[i]) { return false }
      return true
    }
    return false
  }
}

// compiler.run() results should be a subclass of this
public class RunresultHolder: ValueHolder {
  public let returncode: Int32
  public let sout: String
  public let serr: String

  public init(t: TypeNamespace, _ returncode: Int32, _ sout: String, _ serr: String) {
    self.returncode = returncode
    self.sout = sout
    self.serr = serr
    print(returncode, sout, serr)
    super.init(type: t.types["runresult"]!)
  }

  public init(t: Type, _ returncode: Int32, _ sout: String, _ serr: String) {
    self.returncode = returncode
    self.sout = sout
    self.serr = serr
    super.init(type: t)
  }

  public override func clone() -> ValueHolder {
    return RunresultHolder(t: self.type, self.returncode, self.sout, self.serr)
  }

  public override func equals(_ other: ValueHolder) -> Bool {
    if let lh = other as? RunresultHolder {
      return self.returncode == lh.returncode && self.sout == lh.sout && self.serr == lh.serr
    }
    return false
  }

  public override func executeMethod(t: TypeNamespace, args: ArgsObject, name: String)
    -> ValueHolder?
  {
    switch name {
    case "returncode": return IntegerValueHolder(t: t, value: Int(self.returncode))
    case "stdout": return StringValueHolder(t: t, value: self.sout)
    case "stderr": return StringValueHolder(t: t, value: self.serr)
    default: return nil
    }
  }
}
