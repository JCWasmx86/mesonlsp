public class Method: Function {
  public let parent: Type

  init(name: String, parent: Type, returnTypes: [Type] = [`Void`()], args: [Argument] = []) {
    self.parent = parent
    super.init(name: name, returnTypes: returnTypes, args: args)
  }
}
