public class BuildTgt: AbstractObject {
  public let name: String = "build_tgt"
  public let parent: AbstractObject? = Tgt()
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "extract_all_objects", parent: self,
        returnTypes: [
          ExtractedObj()
        ]),
      Method(
        name: "extract_objects", parent: self,
        returnTypes: [
          ExtractedObj()
        ]),
      Method(
        name: "found", parent: self,
        returnTypes: [
          BoolType()
        ]),
      Method(
        name: "full_path", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "name", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "path", parent: self,
        returnTypes: [
          Str()
        ]),
      Method(
        name: "private_dir_include", parent: self,
        returnTypes: [
          Inc()
        ]),
    ]
  }
}
