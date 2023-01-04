public protocol Type {
  var name: String { get }
}

public protocol AbstractObject: Type {
  var parent: AbstractObject? { get }
}
