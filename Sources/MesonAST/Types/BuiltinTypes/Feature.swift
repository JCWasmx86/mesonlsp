public class Feature: AbstractObject {
  public let name: String = "feature"
  public var methods: [Method] = []
  public let parent: AbstractObject? = nil

  public init() {
    self.methods = [
      Method(
        name: "allowed", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "auto", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "disable_auto_if", parent: self,
        returnTypes: [
          self
        ]),
      Method(
        name: "disabled", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "enabled", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "require", parent: self,
        returnTypes: [
          self
        ]),
    ]
  }
}
