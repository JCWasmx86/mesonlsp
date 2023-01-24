public class MesonDocs {
  public var docs: [String: String] = [:]

  public init() { FunctionDocProvider().addToDict(dict: &self.docs) }
}
