public enum Mode {
  case add
  case overwrite
  case append
}

public class Scope {
  public var variables: [String: [Type]] = [:]
}

public class TypeJar {
  public var happenings: [String: Mode] = [:]
}
