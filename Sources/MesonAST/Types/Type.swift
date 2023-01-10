public protocol Type {
  var name: String { get }
  var methods: [Method] { get }
  func getMethod(name: String) -> Method?
  func toString() -> String
}

extension Type {
  public func getMethod(name: String) -> Method? {
    for m in self.methods {
      if m.name == name {
        return m
      }
    }
    return nil
  }
}

extension AbstractObject {
  public func toString() -> String {
    return self.name
  }
}

public protocol AbstractObject: Type {
  var parent: AbstractObject? { get }
}
