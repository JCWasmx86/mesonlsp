public class LazyType: Type {
  public let name: String
  public let methods: [Method]

  public init(name: String) {
		self.name = name
		self.methods = []
  }
}