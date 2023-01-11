public class BuildMachine: AbstractObject {
  public let name: String = "build_machine"
  public let parent: AbstractObject? = nil
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(name: "cpu", parent: self, returnTypes: [Str()]),
      Method(name: "cpu_family", parent: self, returnTypes: [Str()]),
      Method(name: "endian", parent: self, returnTypes: [Str()]),
      Method(name: "system", parent: self, returnTypes: [Str()]),
    ]
  }
}
