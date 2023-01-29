public struct SourceFiles: AbstractObject {
  public let name: String = "sourcefiles"
  public let parent: AbstractObject? = nil
  public var methods: [Method] = []

  public init() {
    self.methods = [

      Method(
        name: "sources",
        parent: self,
        returnTypes: [ListType(types: [Str(), File()])],
        args: []
      ),
      Method(
        name: "dependencies",
        parent: self,
        returnTypes: [ListType(types: [Str(), File()])],
        args: []
      ),
    ]
  }
}
