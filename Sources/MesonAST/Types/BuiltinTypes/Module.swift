public struct Module: AbstractObject {
  public let name: String = "module"
  public var methods: [Method] = []
  public let parent: AbstractObject? = nil

  public init() { self.methods = [Method(name: "found", parent: self, returnTypes: [BoolType()])] }
}
