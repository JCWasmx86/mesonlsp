public struct FSModule: AbstractObject {
  public let name: String = "fs_module"
  public let parent: AbstractObject? = Module()
  public var methods: [Method] = []

  public init() {
    self.methods = [
      Method(
        name: "exists",
        parent: self,
        returnTypes: [BoolType()],
        args: [PositionalArgument(name: "file", types: [Str()])]
      ),
      Method(
        name: "is_dir",
        parent: self,
        returnTypes: [BoolType()],
        args: [PositionalArgument(name: "file", types: [Str()])]
      ),
      Method(
        name: "is_file",
        parent: self,
        returnTypes: [BoolType()],
        args: [PositionalArgument(name: "file", types: [Str()])]
      ),
      Method(
        name: "is_symlink",
        parent: self,
        returnTypes: [BoolType()],
        args: [PositionalArgument(name: "file", types: [Str(), File()])]
      ),
      Method(
        name: "is_absolute",
        parent: self,
        returnTypes: [BoolType()],
        args: [PositionalArgument(name: "file", types: [Str()])]
      ),
      Method(
        name: "hash",
        parent: self,
        returnTypes: [Str()],
        args: [
          PositionalArgument(name: "file", types: [Str(), File()]),
          PositionalArgument(name: "hash_algorithm", types: [Str()]),
        ]
      ),
      Method(
        name: "size",
        parent: self,
        returnTypes: [`IntType`()],
        args: [PositionalArgument(name: "file", types: [Str(), File()])]
      ),
      Method(
        name: "is_samepath",
        parent: self,
        returnTypes: [Str()],
        args: [
          PositionalArgument(name: "path1", types: [Str(), File()]),
          PositionalArgument(name: "path2", types: [Str(), File()]),
        ]
      ),
      Method(
        name: "expand_user",
        parent: self,
        returnTypes: [Str()],
        args: [PositionalArgument(name: "file", types: [Str()])]
      ),
      Method(
        name: "as_posix",
        parent: self,
        returnTypes: [Str()],
        args: [PositionalArgument(name: "file", types: [Str()])]
      ),
      Method(
        name: "replace_suffix",
        parent: self,
        returnTypes: [Str()],
        args: [
          PositionalArgument(name: "file", types: [Str()]),
          PositionalArgument(name: "suffix", types: [Str()]),
        ]
      ),
      Method(
        name: "parent",
        parent: self,
        returnTypes: [Str()],
        args: [PositionalArgument(name: "file", types: [File(), Str()])]
      ),
      Method(
        name: "name",
        parent: self,
        returnTypes: [Str()],
        args: [PositionalArgument(name: "file", types: [File(), Str()])]
      ),
      Method(
        name: "stem",
        parent: self,
        returnTypes: [Str()],
        args: [PositionalArgument(name: "file", types: [File(), Str()])]
      ),
      Method(
        name: "read",
        parent: self,
        returnTypes: [Str()],
        args: [
          PositionalArgument(name: "file", types: [File(), Str()]),
          Kwarg(name: "encoding", opt: true, types: [Str()]),
        ]
      ),
      Method(
        name: "copyfile",
        parent: self,
        returnTypes: [CustomTgt()],
        args: [
          PositionalArgument(name: "src", types: [File(), Str()]),
          PositionalArgument(name: "dst", opt: true, types: [Str()]),
          Kwarg(name: "install", opt: true, types: [BoolType()]),
          Kwarg(name: "install_dir", opt: true, types: [Str()]),
          Kwarg(name: "install_tag", opt: true, types: [Str()]),
          Kwarg(name: "install_mode", opt: true, types: [ListType(types: [Str(), `IntType`()])]),
        ]
      ),
    ]
  }
}
