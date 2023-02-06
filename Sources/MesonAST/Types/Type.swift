public protocol Type {
  var name: String { get }
  var methods: [Method] { get set }
  func getMethod(name: String) -> Method?
  func toString() -> String
}

extension Type {
  public func getMethod(name: String) -> Method? {
    for m in self.methods where m.name == name { return m }
    if let ao = self as? AbstractObject, let aop = ao.parent { return aop.getMethod(name: name) }
    return nil
  }
}

extension AbstractObject { public func toString() -> String { return self.name } }

public protocol AbstractObject: Type { var parent: AbstractObject? { get } }
