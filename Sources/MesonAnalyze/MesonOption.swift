public class MesonOption {
  public let name: String
  public let description: String?

  public init(_ name: String, _ description: String?) {
    self.name = name
    self.description = description
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
