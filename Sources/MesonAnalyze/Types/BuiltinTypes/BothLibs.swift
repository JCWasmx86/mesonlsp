public class BothLibs: AbstractObject {
  public let name: String = "both_libs"
  public let parent: AbstractObject? = Lib()
  public var methods: [Method] = []

  public init() {
    self.methods = []
  }
}
