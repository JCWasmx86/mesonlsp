public class BothLibs: AbstractObject {
  public let name: String = "both_libs"
  public let parent: AbstractObject? = Lib()
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "get_shared_lib", parent: self,
        returnTypes: [
          Lib()
        ]),
      Method(
        name: "get_static_lib", parent: self,
        returnTypes: [
          Lib()
        ]),
    ]
  }
}
