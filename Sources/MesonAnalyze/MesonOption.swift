public class MesonOption {
  public let name: String
  public let description: String?
  public let deprecated: Bool

  public init(_ name: String, _ description: String?, _ deprecated: Bool = false) {
    self.name = name
    self.description = description
    self.deprecated = deprecated
  }
}

public class StringOption: MesonOption {

}

public class IntOption: MesonOption {

}

public class BoolOption: MesonOption {

}

public class ComboOption: MesonOption {

}

public class ArrayOption: MesonOption {

}

public class FeatureOption: MesonOption {

}
