public class Generator: AbstractObject {
  public let name: String = "generator"
  public var methods: [Method] = []
  public let parent: AbstractObject? = nil

  public init() {
    self.methods = [
      Method(
        name: "process", parent: self,
        returnTypes: [
          GeneratedList()
        ])
    ]
  }
}
