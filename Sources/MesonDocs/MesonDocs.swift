public class MesonDocs {
  public var docs: [String: String] = [:]
  public let typeDocs: [String: String] = [
    "build_machine":
      "Provides information about the build machine -- the machine that is doing the actual compilation.",
    "host_machine":
      "Provides information about the host machine -- the machine on which the compiled binary will run.",
    "target_machine":
      "Provides information about the target machine -- the machine on which the compiled binary's output will run.",
    "meson":
      "The `meson` object allows you to introspect various properties of the system. This object is always mapped in the `meson` variable.",
    "any":
      "A placeholder representing all types. This includes builtin, as well as returned objects.",
    "bool": "A boolean object which is either `true` or `false`",
    "dict":
      "Stores a mapping of strings to other objects. You can also iterate over dictionaries with the `foreach` statement.",
    "int":
      "All integer numbers. Meson supports only integer numbers. Hexadecimal, binary and octal literals are supported.",
    "list":
      "An array of elements. An array can contain an arbitrary number of objects of any type. Note appending to an array will always create a new array object instead of modifying the original since all objects in Meson are immutable.",
    "str": "Strings are immutable, all operations return their results as a new string.",
    "void": "Indicates that the function does not return anything. Similar to `void` in C and C++",
  ]

  public init() {
    FunctionDocProvider().addToDict(dict: &self.docs)
    BoolDocProvider().addToDict(dict: &self.docs)
    DictDocProvider().addToDict(dict: &self.docs)
    IntDocProvider().addToDict(dict: &self.docs)
    ListDocProvider().addToDict(dict: &self.docs)
    StrDocProvider().addToDict(dict: &self.docs)
    BuildMachineDocProvider().addToDict(dict: &self.docs)
    MesonDocProvider().addToDict(dict: &self.docs)
    ObjectDocProvider().addToDict(dict: &self.docs)
    BuiltinKwargDocProvider().addToDict(dict: &self.docs)
    CMakeDocProvider().addToDict(dict: &self.docs)
    CudaDocProvider().addToDict(dict: &self.docs)
    DlangDocProvider().addToDict(dict: &self.docs)
    ExternalProjectDocProvider().addToDict(dict: &self.docs)
    FsDocProvider().addToDict(dict: &self.docs)
    GnomeDocProvider().addToDict(dict: &self.docs)
    HotdocDocProvider().addToDict(dict: &self.docs)
    I18nDocProvider().addToDict(dict: &self.docs)
    IcestormDocProvider().addToDict(dict: &self.docs)
    JavaDocProvider().addToDict(dict: &self.docs)
    KeyvalDocProvider().addToDict(dict: &self.docs)
    PkgconfigDocProvider().addToDict(dict: &self.docs)
    PythonDocProvider().addToDict(dict: &self.docs)
    QtDocProvider().addToDict(dict: &self.docs)
    RustDocProvider().addToDict(dict: &self.docs)
    SimdDocProvider().addToDict(dict: &self.docs)
    SourceSetDocProvider().addToDict(dict: &self.docs)
    WaylandDocProvider().addToDict(dict: &self.docs)
    WindowsDocProvider().addToDict(dict: &self.docs)
    ModuleKwargDocProvider().addToDict(dict: &self.docs)
  }

  public func findDocs(id: String) -> String? { return self.docs[id] }
}
