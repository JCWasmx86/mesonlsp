public class MesonDocs {
  public var docs: [String: String] = [:]

  public init() { FunctionDocProvider().addToDict(dict: &self.docs) }

  public func find_docs(id: String) -> String? { return self.docs[id] }
}
