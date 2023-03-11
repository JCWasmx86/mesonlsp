import MesonAST

open class ValueHolder {
  let type: Type

  public init(type: Type) { self.type = type }

  open func clone() -> ValueHolder { return ValueHolder(type: self.type) }
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
}
