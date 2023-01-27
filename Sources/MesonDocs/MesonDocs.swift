public class MesonDocs {
  public var docs: [String: String] = [:]

  public init() {
    FunctionDocProvider().addToDict(dict: &self.docs)
    BoolDocProvider().addToDict(dict: &self.docs)
    DictDocProvider().addToDict(dict: &self.docs)
    IntDocProvider().addToDict(dict: &self.docs)
    ListDocProvider().addToDict(dict: &self.docs)
    StrDocProvider().addToDict(dict: &self.docs)
    BuildMachineDocProvider().addToDict(dict: &self.docs)
    HostMachineDocProvider().addToDict(dict: &self.docs)
    TargetMachineDocProvider().addToDict(dict: &self.docs)
    MesonDocProvider().addToDict(dict: &self.docs)
    ObjectDocProvider().addToDict(dict: &self.docs)
    BuiltinKwargDocProvider().addToDict(dict: &self.docs)
  }

  public func find_docs(id: String) -> String? { return self.docs[id] }
}
