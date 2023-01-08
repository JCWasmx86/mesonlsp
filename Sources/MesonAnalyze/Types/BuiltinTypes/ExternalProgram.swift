public class ExternalProgram: AbstractObject {
  public let name: String = "external_program"
  public var methods: [Method] = []
  public let parent: AbstractObject? = nil

  public init() {
    self.methods = [
      Method(
        name: "found", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "full_path", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "path", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "version", parent: self,
        returnTypes: [
          Str()
        ]),
    ]
  }
}
