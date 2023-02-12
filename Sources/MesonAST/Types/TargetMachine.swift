public struct TargetMachine: AbstractObject {
  public let name: String = "target_machine"
  public let parent: AbstractObject? = BuildMachine()

  public init() {}
}
