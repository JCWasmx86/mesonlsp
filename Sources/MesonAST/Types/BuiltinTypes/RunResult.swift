public struct RunResult: AbstractObject {
  public let name: String = "runresult"
  public var methods: [Method] = []
  public let parent: AbstractObject? = nil

  public init() {
    self.methods = [
      Method(name: "compiled", parent: self, returnTypes: [BoolType()]),
      Method(name: "returncode", parent: self, returnTypes: [`IntType`()]),
      Method(name: "stderr", parent: self, returnTypes: [Str()]),
      Method(name: "stdout", parent: self, returnTypes: [Str()]),
    ]
  }
}
