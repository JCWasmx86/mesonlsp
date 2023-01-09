public protocol Type {
  var name: String { get }
  var methods: [Method] { get }
}

public protocol AbstractObject: Type {
  var parent: AbstractObject? { get }
}
