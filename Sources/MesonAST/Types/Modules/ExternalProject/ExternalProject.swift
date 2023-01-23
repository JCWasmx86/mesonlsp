public class ExternalProject: AbstractObject {
  public let name: String = "external_project"
  public let parent: AbstractObject? = nil
  public var methods: [Method] = []

  public init() {
    self.methods = [
    	Method(name: "dependency", parent: self, returnTypes: [Dep()], args: [
				PositionalArgument(name: "subdir", types: [Str()]),
          Kwarg(name: "subdir", opt: true, types: [Str()]),
    	])
    ]
  }
}
