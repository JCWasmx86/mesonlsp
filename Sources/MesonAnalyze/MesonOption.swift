public class MesonOption {
  public let name: String
  public let description: String?
  public let deprecated: Bool
  public var type: String { return "<<>>" }

  public init(_ name: String, _ description: String?, _ deprecated: Bool = false) {
    self.name = name
    self.description = description
    self.deprecated = deprecated
  }
}

public class StringOption: MesonOption { public override var type: String { return "string" } }

public class IntOption: MesonOption { public override var type: String { return "int" } }

public class BoolOption: MesonOption { public override var type: String { return "boolean" } }

public class ComboOption: MesonOption {
  public let values: [String]?

  public init(
    _ name: String,
    _ description: String?,
    _ deprecated: Bool = false,
    _ vals: [String]? = nil
  ) {
    self.values = vals
    super.init(name, description, deprecated)
  }

  public override var type: String { return "combo" }
}

public class ArrayOption: MesonOption { public override var type: String { return "array" } }

public class FeatureOption: MesonOption { public override var type: String { return "feature" } }
