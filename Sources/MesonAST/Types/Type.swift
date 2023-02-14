public protocol Type: AnyObject {
  var name: String { get }
  func getMethod(name: String, ns: TypeNamespace) -> Method?
  func toString() -> String
}

extension Type {
  public func getMethod(name: String, ns: TypeNamespace) -> Method? {
    for m in ns.vtables[self.name]! where m.name == name { return m }
    if let ao = self as? AbstractObject, let aop = ao.parent {
      return aop.getMethod(name: name, ns: ns)
    }
    return nil
  }
}

extension AbstractObject { public func toString() -> String { return self.name } }

public protocol AbstractObject: Type { var parent: AbstractObject? { get } }
