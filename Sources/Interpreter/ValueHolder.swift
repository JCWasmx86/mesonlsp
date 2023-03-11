import MesonAST

open class ValueHolder {
  let type: Type

  public init(type: Type) { self.type = type }

  open func clone() -> ValueHolder { return ValueHolder(type: self.type) }

  open func equals(_ other: ValueHolder) -> Bool { return self.type.name == other.type.name }
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
