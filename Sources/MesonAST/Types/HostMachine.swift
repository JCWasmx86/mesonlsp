public class HostMachine: AbstractObject {
  public let name: String = "host_machine"
  public let parent: AbstractObject? = BuildMachine()

  public init() {}
}
